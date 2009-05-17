/*
  Copyright (c) 2009 Simon Russell.  All rights reserved.
*/


#include <ruby.h>
#include <node.h>
#include <env.h>

enum INSTRUCTIONS {
  VM_NOP = 0,

  VM_RETURN = 5,

  VM_CALL = 9,
  VM_CALL_0 = 10,
  VM_CALL_1,
  VM_CALL_2,
  VM_CALL_3,
  VM_CALL_4,

  VM_JUMP = 50,
  VM_JUMP_TRUE,
  VM_JUMP_FALSE,

  VM_MOVE = 60
};

static inline
VALUE load_reg(int reg_num, VALUE *regs, int reg_len, VALUE *code, int code_len, VALUE self)
{
  if (reg_num == 0)
  {
    return Qnil;
  }
  else if (reg_num == 1)
  {
    return self;
  }
  else if (reg_num < 0)
  {
    return code[code_len + reg_num];
  }
  else
  {
    // local regs
    return regs[reg_num];
  }
}

static inline
void store_reg(int reg_num, VALUE *regs, int reg_len, VALUE value)
{
  if (reg_num == 0)
  {
    // nothing, void
  }
  else if (reg_num > 1 && reg_num < reg_len)
  {
    regs[reg_num] = value;
  }
  else
  {
    rb_raise(rb_eStandardError, "storing to register %d invalid", reg_num);
  }
}

static inline
VALUE do_funcall1(VALUE target, ID method, VALUE arg)
{
  // Just as an example
  if (FIXNUM_P(target) && FIXNUM_P(arg))
  {
    long a = FIX2LONG(target);
    long b = FIX2LONG(arg);
    
    switch(method)
    {
      case '+':   a += b; break;
      case '-':   a -= b; break;
      default:    goto other;
    }

    return LONG2NUM(a);
  }
    
  // just do the work  
other:
  return rb_funcall2(target, method, 1, &arg);
}

#define NEXT_IP   (code[ip++])
#define NEXT_IP_INT  FIX2INT(NEXT_IP)
#define LOAD_REG(x)    (load_reg((x), regs, reg_len, code, code_len, self))
#define STORE_REG(x, v) (store_reg((x), regs, reg_len, (v)))
#define CURRENT_OP   (code[ip - 1])

static
VALUE execute_linear(VALUE self, VALUE code_array)
{
  Check_Type(code_array, T_ARRAY);
  
  VALUE *code = RARRAY(code_array)->ptr;
  int code_len = RARRAY(code_array)->len;
  VALUE result = Qundef;
  int ip = 1;
  int i;

  int reg_len = FIX2INT(code[0]);
  VALUE *regs = (reg_len > 2 ? ALLOCA_N(VALUE, reg_len) : NULL);   // if reg_len is one, they only have default void reg (Qnil)
  if (regs) for (i = 0; i < reg_len; i++) regs[i] = Qnil;

  int dest_reg;
  VALUE value;
  VALUE call_args[4];
  VALUE call_target;
  ID call_method;

  while(result == Qundef)
  {
/*    if (regs)
      for (i = 0; i < reg_len; i++)
        rb_p(regs[i]);*/

    // we're going to trust the instructions have been verified
    switch(NEXT_IP_INT)
    {
      case VM_NOP:
        // it's a nop.
        break;

      case VM_JUMP:     // always jump
        ip = FIX2INT(code[ip]);
        break;

      case VM_MOVE:   // copy value from one reg to another
        dest_reg = NEXT_IP_INT;
        STORE_REG(dest_reg, LOAD_REG(NEXT_IP_INT));
        break;

      case VM_JUMP_TRUE:    // jump if reg contains ruby true
        if (RTEST(LOAD_REG(NEXT_IP_INT)))
          ip = FIX2INT(code[ip]);
        else
          NEXT_IP;    // skip over destination
        break;

      case VM_JUMP_FALSE:     // jump if reg is false (according to ruby)
        if (!RTEST(LOAD_REG(NEXT_IP_INT)))
          ip = FIX2INT(code[ip]);
        else
          NEXT_IP;    // skip over destination
        break;

      case VM_RETURN:
        result = LOAD_REG(NEXT_IP_INT);
        break;

      case VM_CALL_0:
        dest_reg = NEXT_IP_INT;
        call_target = LOAD_REG(NEXT_IP_INT);
        call_method = (ID) NEXT_IP_INT;
        STORE_REG(dest_reg, rb_funcall2(call_target, call_method, 0, NULL));
        break;
        
      case VM_CALL_1:
        dest_reg = NEXT_IP_INT;
        call_target = LOAD_REG(NEXT_IP_INT);
        call_method = (ID) NEXT_IP_INT;
        value = LOAD_REG(NEXT_IP_INT);
        STORE_REG(dest_reg, do_funcall1(call_target, call_method, value));
        break;

      default:
        rb_raise(rb_eStandardError, "invalid opcode %d", CURRENT_OP);
        break;
    }
  }

  return result;
}



























static VALUE plus_operator;
static VALUE one;

static
VALUE addtest1(VALUE self)
{
  return INT2FIX(1 + 1);
}

static
VALUE addtest1_loop(VALUE self, VALUE multiple)
{
  int i = NUM2INT(multiple);

  for (; i > 0; i--)
    addtest1(self);

  return Qnil;
}

static
VALUE addtest2(VALUE self)
{
  return rb_funcall2(one, SYM2ID(plus_operator), 1, &one);
}

static
VALUE addtest2_loop(VALUE self, VALUE multiple)
{
  int i = NUM2INT(multiple);

  for (; i > 0; i--)
    addtest2(self);

  return Qnil;
}

static 
VALUE addtest3_inner(VALUE x)
{
  return rb_funcall2(one, SYM2ID(plus_operator), 1, &x);
}

static 
VALUE addtest3(VALUE self, VALUE multiple)
{
  return rb_block_call(multiple, rb_intern("times"), 0, NULL, addtest3_inner, multiple);
}

static VALUE execute_call_symbol;
static VALUE execute_block_call_symbol;

#define FAST_TOSYM(v) (SYMBOL_P(v) ? SYM2ID(v) : rb_to_id(v))

static 
VALUE execute(VALUE self, VALUE code)
{
  Check_Type(code, T_ARRAY);
  
  long i;
  VALUE result = Qnil;

  for (i = 0; i < RARRAY(code)->len; i++)
  {
    VALUE op = RARRAY(code)->ptr[i];
    Check_Type(op, T_ARRAY);
 
    if (RARRAY(op)->len < 1) rb_raise(rb_eStandardError, "invalid op");

    VALUE opcode = RARRAY(op)->ptr[0];

    if (opcode == execute_call_symbol)
    {
      if (RARRAY(op)->len < 3) rb_raise(rb_eStandardError, "call needs recv, method, *args");

      result = rb_funcall2(RARRAY(op)->ptr[1], FAST_TOSYM(RARRAY(op)->ptr[2]), RARRAY(op)->len - 3, RARRAY(op)->ptr + 3);
    }
    else if (opcode == execute_block_call_symbol)
    {
      if (RARRAY(op)->len < 4) rb_raise(rb_eStandardError, "call needs recv, method, *args, [blockdef]");

      result = rb_block_call(RARRAY(op)->ptr[1], FAST_TOSYM(RARRAY(op)->ptr[2]), RARRAY(op)->len - 4, RARRAY(op)->ptr + 3, execute, RARRAY(op)->ptr[RARRAY(op)->len - 1]);
    }
    else
    {
      rb_raise(rb_eStandardError, "unknown op");
    }
  }

  return result;
}

VALUE test_pass(VALUE self)
{
  rb_p(self);
  NODE *me_node = rb_method_node(self, ruby_frame->last_func);
  rb_p(me_node->u3.value);
  
  return Qnil;
}

static
VALUE execute_node(VALUE self)
{
  NODE *me_node = rb_method_node(CLASS_OF(self), ruby_frame->last_func);
  return execute(self, me_node->u3.value);
}

static
VALUE define_accelerator_method(VALUE self, VALUE klass, VALUE name, VALUE body)
{
  Check_Type(klass, T_CLASS);
  Check_Type(name, T_SYMBOL);
  Check_Type(body, T_ARRAY);
   
  rb_define_method(klass, rb_id2name(SYM2ID(name)), execute_node, 0);
  NODE *node = rb_method_node(klass, SYM2ID(name));
  node->u3.value = body;

  return Qnil;
}

void Init_ruby_accelerator(void)
{
  VALUE module = rb_define_module("RubyAccelerator");

  rb_define_module_function(module, "addtest1", addtest1, 0);
  rb_define_module_function(module, "addtest1_loop", addtest1_loop, 1);

  rb_define_module_function(module, "addtest2", addtest2, 0);
  rb_define_module_function(module, "addtest2_loop", addtest2_loop, 1);

  rb_define_module_function(module, "addtest3", addtest3, 1);

  rb_define_module_function(module, "execute", execute, 1);
  rb_define_module_function(module, "execute_linear", execute_linear, 1);
  rb_define_module_function(module, "test_pass", test_pass, 0);

  rb_define_module_function(module, "define_accelerator_method", define_accelerator_method, 3);

  plus_operator = ID2SYM(rb_intern("+"));
  one = INT2NUM(1);

  execute_call_symbol = ID2SYM(rb_intern("call"));
  execute_block_call_symbol = ID2SYM(rb_intern("block_call"));


  NODE *node = rb_method_node(module, rb_intern("test_pass"));
  node->u3.value = rb_str_new2("hello world");
}
