describe 'optimization' do
  def compiled_code(haml)
    Hamlit::Engine.new.call(haml)
  end

  describe 'static analysis' do
    it 'renders static value for href statically' do
      haml = %|%a{ href: 1 }|
      assert_equal true, compiled_code(haml).include?(%|href='1'|)
    end

    it 'renders a static part of string interpolation statically' do
      haml = %q|%input{ value: "jruby#{9000}#{dynamic}" }|
      assert_equal true, compiled_code(haml).include?(%|value='jruby9000|)
    end

    it 'renders inline static script statically' do
      haml = %|%span= 1|
      assert_equal true, compiled_code(haml).include?(%|<span>1</span>|)
    end
  end
end
