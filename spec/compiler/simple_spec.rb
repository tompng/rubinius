require File.dirname(__FILE__) + "/spec_helper"

describe Compiler do
  it "compiles 'true'" do
    ruby = <<-EOC
      true
    EOC

    sexp = s(:true)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :true
    end
  end

  it "compiles 'false'" do
    ruby = <<-EOC
      false
    EOC

    sexp = s(:false)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :false
    end
  end

  it "compiles 'nil'" do
    ruby = <<-EOC
      nil
    EOC

    sexp = s(:nil)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :nil
    end
  end

  it "compiles 'self'" do
    ruby = <<-EOC
      self
    EOC

    sexp = s(:self)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :self
    end
  end

  it "compiles 'true and false'" do
    ruby = <<-EOC
      true and false
    EOC

    sexp = s(:and, s(:true), s(:false))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :true
      g.dup
      lbl = g.new_label
      g.gif lbl
      g.pop
      g.push :false
      lbl.set!
    end
  end

  it "compiles 'true or false'" do
    ruby = <<-EOC
      true or false
    EOC

    sexp = s(:or, s(:true), s(:false))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :true
      g.dup
      lbl = g.new_label
      g.git lbl
      g.pop
      g.push :false
      lbl.set!
    end
  end

  it "compiles 'not true'" do
    ruby = <<-EOC
      not true
    EOC

    sexp = s(:not, s(:true))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :true
      tru = g.new_label
      fin = g.new_label
      g.git tru
      g.push :true
      g.goto fin
      tru.set!
      g.push :false
      fin.set!
    end
  end

  it "compiles '3'" do
    ruby = <<-EOC
      3
    EOC

    sexp = s(:fixnum, 3)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push 3
    end
  end

  it "compiles ':blah'" do
    ruby = <<-EOC
      :blah
    EOC

    sexp = s(:lit, :blah)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_unique_literal :blah
    end
  end

  it "compiles bignums '0xffff_ffff_ffff_ffff'" do
    num = 0xffff_ffff_ffff_ffff
    ruby = <<-EOC
      0xffff_ffff_ffff_ffff
    EOC

    sexp = s(:lit, num)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_unique_literal num
    end
  end

  it "compiles floats '1.2'" do
    num = 1.2
    ruby = <<-EOC
      1.2
    EOC

    sexp = s(:lit, num)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_unique_literal num
    end
  end

  it "compiles strings '%(blah)'" do
    ruby = <<-EOC
      "blah"
    EOC

    sexp = s(:lit, "blah")

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_unique_literal "blah"
    end
  end

  it "compiles negate with fixnum '-10'" do
    ruby = <<-EOC
      -10
    EOC

    sexp = s(:negate, s(:fixnum, 10))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push(-10)
    end
  end

  it "compiles negate with anything else '-%(str)'" do
    ruby = <<-EOC
      -"str"
    EOC

    sexp = s(:negate, s(:str, "str"))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_literal "str"
      g.string_dup
      g.send :"-@", 0
    end
  end

  it "compiles regexen '/comp/'" do
    ruby = <<-EOC
      /comp/
    EOC

    sexp = s(:regex, "comp", 0)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      idx = g.add_literal(nil)
      g.push_literal_at idx
      g.dup
      g.is_nil

      lbl = g.new_label
      g.gif lbl
      g.pop

      g.push_const :Regexp
      g.push_literal "comp"
      g.push 0
      g.send :new, 2
      g.set_literal idx
      lbl.set!
    end
  end

  it "compiles dynamic strings" do
    ruby = <<-'EOC'
      "hello #{true}!"
    EOC

    sexp = s(:dstr, "hello ", s(:evstr, s(:true)), s(:str, "!"))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_literal "!"
      g.string_dup
      g.push :true
      g.send :to_s, 0, true
      g.push_literal "hello "
      g.string_dup
      g.string_append
      g.string_append
    end
  end

  it "compiles empty dynamic strings" do
    ruby = <<-'EOC'
      "hello #{}"
    EOC

    sexp = s(:dstr, "hello ", s(:evstr))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_literal ""
      g.string_dup
      g.send :to_s, 0, true
      g.push_literal "hello "
      g.string_dup
      g.string_append
    end
  end

  it "compiles dynamic regexs" do
    ruby = <<-'EOC'
      /(#{true})/
    EOC

    sexp = s(:dregx, "(", s(:evstr, s(:true)), s(:str, ")"), 0)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_const :Regexp
      g.push_literal ")"
      g.string_dup
      g.push :true
      g.send :to_s, 0, true
      g.push_literal "("
      g.string_dup
      g.string_append
      g.string_append
      g.push 0
      g.send :new, 2
    end
  end

  it "compiles empty dynamic regexs" do
    ruby = <<-'EOC'
      /(#{})/
    EOC

    sexp = s(:dregx, "(", s(:evstr), s(:str, ")"), 0)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_const :Regexp
      g.push_literal ")"
      g.string_dup
      g.push_literal ""
      g.string_dup
      g.send :to_s, 0, true
      g.push_literal "("
      g.string_dup
      g.string_append
      g.string_append
      g.push 0
      g.send :new, 2
    end
  end

  it "compiles a dynamic regex once is indicated" do
    ruby = <<-'EOC'
      /(#{true})/o
    EOC

    sexp = s(:dregx_once, "(", s(:evstr, s(:true)), s(:str, ")"), 0)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      idx = g.add_literal nil
      g.push_literal_at idx
      g.dup
      g.is_nil

      lbl = g.new_label
      g.gif lbl
      g.pop

      g.push_const :Regexp
      g.push_literal ")"
      g.string_dup
      g.push :true
      g.send :to_s, 0, true
      g.push_literal "("
      g.string_dup
      g.string_append
      g.string_append
      g.push 0

      g.send :new, 2

      g.set_literal idx
      lbl.set!
    end
  end

  it "compiles implicit regexp operation '42 if /bunnies/'" do
    ruby = <<-EOC
      42 if /bunnies/
    EOC

    sexp = s(:if, s(:match, "bunnies", 0), nil, nil)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_literal :$_
      g.push_cpath_top
      g.find_const :Globals
      g.send :[], 1

      i = g.add_literal nil
      g.push_literal_at i
      g.dup
      g.is_nil

      label = g.new_label
      g.gif label
      g.pop

      g.push_const :Regexp
      g.push_literal "bunnies"
      g.push 0
      g.send :new, 2
      g.set_literal i

      label.set!        # The nil from above drops here to get the comparison

      g.send :=~, 1

      g.pop
      g.push :nil
    end
  end

  it "compiles regexp operation '/aoeu/ =~ %(blah)'" do
    ruby = <<-EOC
      /aoeu/ =~ %(blah)
    EOC

    sexp = s(:match2, s(:regex, "aoeu", 0), s(:str, "blah"))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      lbl = g.new_label

      idx = g.add_literal(nil)
      g.push_literal_at idx
      g.dup
      g.is_nil

      g.gif lbl
      g.pop

      g.push_const :Regexp
      g.push_literal "aoeu"
      g.push 0
      g.send :new, 2
      g.set_literal idx
      lbl.set!

      g.push_literal "blah"
      g.string_dup

      g.send :=~, 1
    end
  end

  it "compiles string operation '%(blah) =~ /aoeu/'" do
    ruby = <<-EOC
      %(blah) =~ /aoeu/
    EOC

    sexp = s(:match3, s(:regex, "aoeu", 0), s(:str, "blah"))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      lbl = g.new_label

      g.push_literal "blah"
      g.string_dup

      idx = g.add_literal(nil)
      g.push_literal_at idx
      g.dup
      g.is_nil

      g.gif lbl
      g.pop

      g.push_const :Regexp
      g.push_literal "aoeu"
      g.push 0
      g.send :new, 2

      g.set_literal idx
      lbl.set!

      g.send :=~, 1
    end
  end

  it "compiles regexp back references '$&'" do
    ruby = <<-EOC
      $&
    EOC

    sexp = s(:back_ref, 38)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_context
      g.push_literal :&
      g.send :back_ref, 1
    end
  end

  it "compiles regexp last match captures '$3'" do
    ruby = <<-EOC
      $3
    EOC

    sexp = s(:nth_ref, 3)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_context
      g.push 3
      g.send :nth_ref, 1
    end
  end

  it "compiles a literal array '[12, 13]'" do
    ruby = <<-EOC
      [12, 13]
    EOC

    sexp = s(:array, s(:fixnum, 12), s(:fixnum, 13))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push 12
      g.push 13
      g.make_array 2
    end
  end

  it "compiles an empty array '[]'" do
    ruby = <<-EOC
      []
    EOC

    sexp = s(:zarray)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.make_array 0
    end
  end

  it "compiles a hash literal '{ 12 => 13, 14 => 15 }'" do
    x = [:hash,
         [:fixnum, 12], [:fixnum, 13],
         [:fixnum, 14], [:fixnum, 15]]

    gen x do |g|
      g.push_cpath_top
      g.find_const :Hash
      g.push 12
      g.push 13
      g.push 14
      g.push 15
      g.send :[], 4
    end
  end

  it "compiles an svalue 'a = *b'" do
    ruby = <<-EOC
      a = *b
    EOC

    sexp = s(:svalue, s(:vcall, :ab))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      lbl = g.new_label

      g.push :self
      g.send :ab, 0, true
      g.cast_array
      g.dup
      g.send :size, 0
      g.push 1
      g.swap
      g.send :<, 1

      g.git lbl

      g.push 0
      g.send :at, 1

      lbl.set!
    end
  end

  it "compiles a splat 'a(*b)'" do
    ruby = <<-EOC
      a(*b)
    EOC

    sexp = s(:splat, s(:fixnum, 12))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push 12
      g.cast_array
    end
  end

  it "compiles :to_ary 'a, b = c'" do
    ruby = <<-EOC
      a, b = c
    EOC

    sexp = s(:to_ary, s(:fixnum, 12))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push 12
      g.cast_array
    end
  end

  it "compiles '`ls`'" do
    ruby = <<-EOC
      `ls`
    EOC

    sexp = s(:xstr, "ls")

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :self
      g.push_literal "ls"
      g.string_dup
      g.send :`, 1, true #` (silly emacs/vim)
    end
  end

  it "compiles '`ls \#{dir}`'" do
    ruby = <<-EOC
      `ls \#{dir}`
    EOC

    sexp = s(:dxstr, "ls ", s(:evstr, s(:vcall, :dir)))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :self
      g.push :self
      g.send :dir, 0, true
      g.send :to_s, 0, true
      g.push_literal "ls "
      g.string_dup
      g.string_append
      g.send :`, 1, true  #`
    end
  end

  it "compiles ':\"you \#{thing}\"'" do
    ruby = <<-EOC
      :\"you \#{thing}\"
    EOC

    sexp = s(:dsym, s(:dstr, "you ", s(:evstr, s(:vcall, :thing))))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :self
      g.send :thing, 0, true
      g.send :to_s, 0, true
      g.push_literal "you "
      g.string_dup
      g.string_append
      g.send :to_sym, 0, true
    end

  end

  it "compiles 'alias a b'" do
    ruby = <<-EOC
      alias a b
    EOC

    sexp = s(:alias, :b, :a)

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push :self
      g.push_literal :a
      g.push_literal :b
      g.send :alias_method, 2, true
    end
  end

  it "compiles '1..2'" do
    ruby = <<-EOC
      1..2
    EOC

    sexp = s(:dot2, s(:fixnum, 1), s(:fixnum, 2))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_cpath_top
      g.find_const :Range
      g.push 1
      g.push 2
      g.send :new, 2
    end
  end

  it "compiles '1...2'" do
    ruby = <<-EOC
      1...2
    EOC

    sexp = s(:dot3, s(:fixnum, 1), s(:fixnum, 2))

    sexp.should == parse(ruby) if $unified && $new

    gen sexp do |g|
      g.push_cpath_top
      g.find_const :Range
      g.push 1
      g.push 2
      g.push :true
      g.send :new, 3
    end
  end
end
