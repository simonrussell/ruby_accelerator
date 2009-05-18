module RubyAccelerator
  module Assembler
    
    OP_MAP = {
      :nop => 0,
      :block => 4,
      :return => 5,
      
      :call_0 => 10,
      :call_1 => 11,

      :jump => 50,
      :jump_true => 51,
      :jump_false => 52,

      :move => 60
    }


    def self.assemble_reg(reg, regs, const_map)
      raise "invalid reg #{reg}" unless reg.is_a?(Symbol)

      if const_map.key?(reg)
        const_map[reg] - const_map.length
      elsif regs.key?(reg)
        regs[reg]
      else
        raise "unknown source reg #{reg}"
      end
    end

    def self.assemble_dest_reg(reg, regs, const_map)
      raise "invalid reg #{reg}" unless reg.is_a?(Symbol)

      if const_map.key?(reg)
        raise "dest reg with same name as constant #{reg}"
      elsif regs.key?(reg)
        regs[reg]
      else
        regs[reg] = regs.length
      end
    end

    def self.assemble(asm)
      if asm.first.is_a?(Hash)
        consts = asm.first
        asm = asm[1..-1]
      else
        consts = {}
      end

      result = [0]
      labels = {}
      regs = { :void => 0, :self => 1 }

      # map the consts
      const_array = []
      const_map = {}
      consts.each do |k, v|
        const_array << v
        const_map[k] = const_array.length - 1
      end

      # put opcodes in
      for op in asm
        if op.is_a?(Symbol)
          labels[op] = result.length
        else
          #puts "#{result.length}: #{op.inspect}"

          raise "invalid opcode #{op.first}" unless OP_MAP.key?(op.first)

          result << OP_MAP[op.first]

          case op.first
          when :nop
            # nothing

          when :return
            result << assemble_reg(op[1], regs, const_map)

          when :block
            result << op[1]

          when :jump
            result << op[1]

          when :jump_true, :jump_false
            result << assemble_reg(op[1], regs, const_map)
            result << op[2]

          when :call_0
            result << assemble_dest_reg(op[1], regs, const_map)
            result << assemble_reg(op[2], regs, const_map)
            result << op[3].to_i

          when :call_1
            result << assemble_dest_reg(op[1], regs, const_map)
            result << assemble_reg(op[2], regs, const_map)
            result << op[3].to_i
            result << assemble_reg(op[4], regs, const_map)

          when :move
            result << assemble_dest_reg(op[1], regs, const_map)
            result << assemble_reg(op[2], regs, const_map)

          else
            raise "invalid opcode #{op.first}"
          end
        end
      end

      # fixup labels
      result.map! { |r| r.is_a?(Symbol) ? labels[r] : r }

      result[0] = regs.length
      result + const_array
    end

  end
end
