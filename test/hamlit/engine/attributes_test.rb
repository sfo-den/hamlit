describe Hamlit::Engine do
  include RenderAssertion

  describe 'id attributes' do
    specify 'compatilibity' do
      assert_haml(<<-HAML)
        #a
        #a{ id: nil }
        #a{ id: nil }(id=nil)
        #a{ id: false }
        #a{ id: 'b' }
        #b{ id: 'a' }
        - id = 'c'
        #a{ id: 'b' }(id=id)
        - id = 'b'
        #c{ id: a = 'a' }(id=id)
        - id = 'a'
        #d#c{ id: a = 'b' }(id=id)
        #d#c{ id: %w[b e] }(id=id)
        - hash = { id: 'a' }
        %div{ hash }
        #b{ hash }
        #b{ hash }(id='c')
        - id = 'c'
        #b{ hash }(id=id)
      HAML
    end

    specify 'incompatibility' do
      assert_render(%q|#a{ id: [] }|, %Q|<div id='a'></div>\n|)
      assert_render(%q|%a{ id: [nil, false] }|, %Q|<a id=''></a>\n|)
      assert_render(<<-HAML, <<-HTML)
        - id = 'a'
        #d#c{ id: [] }(id=id)
      HAML
        <div id='c_a'></div>
      HTML
    end
  end

  describe 'class attributes' do
    specify 'compatibility' do
      assert_inline(%q|.bar.foo|)
      assert_inline(%q|.foo.bar|)
      assert_inline(%Q|%div(class='bar foo')|)
      assert_inline(%Q|%div(class='foo bar')|)
      assert_inline(%Q|%div{ class: 'bar foo' }|)
      assert_haml(<<-HAML)
        - klass = 'b a'
        .b.a
        .b{ class: 'a' }
        .a{ class: 'b a' }
        .b.a{ class: 'b a' }
        .b{ class: 'b a' }
        .a{ class: klass }
        .b{ class: klass }
        .b.a{ class: klass }
        .b{ class: 'c a' }
        .b{ class: 'a c' }
        .a{ class: [] }
        .a{ class: %w[c b] }
        %div{ class: 'b a' }(class=klass)
        %div(class=klass){ class: 'b a' }
        .a.d(class=klass){ class: 'c d' }
        .a.d(class=klass)
        .a.c(class='b')
        - klass = nil
        .a{:class => nil}
        .a{:class => false}
        .a{:class => klass}
        .a{:class => nil}(class=klass)
        - hash = { class: nil }
        .b{ hash, class: 'a' }
        .b{ hash, 'class' => 'a' }
        - hash = { class: 'd' }
        .a{ hash }
        .b{ hash, class: 'a' }(class='c')
        .b{ hash, class: 'a' }(class=klass)
      HAML
    end

    specify 'incompatibility' do
      assert_render(%q|%div{ class: 'b a' }|, %Q|<div class='a b'></div>\n|)
      assert_render(<<-HAML, <<-HTML)
        - klass = 'b a'
        %div{ class: klass }
      HAML
        <div class='a b'></div>
      HTML
    end
  end

  specify 'data attributes' do
    assert_haml(<<-HAML)
      - val = false
      #foo.bar{ data: { disabled: val } }
      - hash = {:a => {:b => 'c'}}
      - hash[:d] = hash
      %div{:data => hash}
      - hash = { data: hash }
      %div{ hash }
      %div{:data => {:foo_bar => 'blip', :baz => 'bang'}}
      %div{ data: { raw_src: 'foo' } }
      %a{ data: { value: [count: 1] } }
      %a{ 'data-disabled' => true }
      %a{ :'data-disabled' => true }
      %a{ data: { nil => 3 } }
      %a{ data: 3 }
    HAML
  end

  specify 'boolean attributes' do
    assert_haml(<<-HAML)
      %input{ disabled: nil }
      %input{ disabled: false }
      %input{ disabled: true }
      %input{ disabled: 'false' }
      %input{ disabled: val = nil }
      %input{ disabled: val = false }
      %input{ disabled: val = true }
      %input{ disabled: val = 'false' }
      %input{ disabled: nil }(disabled=true)
      %input{ disabled: false }(disabled=true)
      %input{ disabled: true }(disabled=false)
      - hash = { disabled: false }
      %a{ hash }
      - hash = { disabled: nil }
      %a{ hash }
      %input(disabled=true){ disabled: nil }
      %input(disabled=true){ disabled: false }
      %input(disabled=false){ disabled: true }
      - val = true
      %input(disabled=val){ disabled: false }
      - val = false
      %input(disabled=val)
      %input(disabled=nil)
      %input(disabled=false)
      %input(disabled=true)
      %input(disabled='false')
      - val = 'false'
      %input(disabled=val)
      %input(disabled='false'){ disabled: true }
      %input(disabled='false'){ disabled: false }
      %input(disabled='false'){ disabled: nil }
      %input(disabled=''){ disabled: nil }
    HAML

    assert_inline(%q|%input(checked=true)|)
    assert_inline(%q|%input(checked=true)|, format: :xhtml)
  end

  describe 'common attributes' do
    specify 'compatibility' do
      assert_inline(%Q|%a{ href: '/search?foo=bar&hoge=<fuga>' }|)
      assert_haml(<<-HAML)
        - new = 'new'
        - old = 'old'
        %span(foo='new'){ foo: 'old' }
        %span{ foo: 'old' }(foo='new')
        %span(foo=new){ foo: 'old' }
        %span{ foo: 'old' }(foo=new)
        %span(foo=new){ foo: old }
        %span{ foo: old }(foo=new)
      HAML
    end

    specify 'incompatibility' do
      assert_render(%q|%a{ href: "'\"" }|, %Q|<a href='&#39;&quot;'></a>\n|)
    end
  end

  describe 'engine options' do
    specify 'attr_quote' do
      assert_render(%q|%a{ href: '/' }|, %Q|<a href='/'></a>\n|)
      assert_render(%q|%a{ href: '/' }|, %Q|<a href='/'></a>\n|, attr_quote: ?')
      assert_render(%q|%a{ href: '/' }|, %Q|<a href=*/*></a>\n|, attr_quote: ?*)

      assert_render(%q|%a{ id: '/' }|, %Q|<a id="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = '/'\n%a{ id: val }|, %Q|<a id="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- hash = { id: '/' }\n%a{ hash }|, %Q|<a id="/"></a>\n|, attr_quote: ?")

      assert_render(%q|%a{ class: '/' }|, %Q|<a class="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = '/'\n%a{ class: val }|, %Q|<a class="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- hash = { class: '/' }\n%a{ hash }|, %Q|<a class="/"></a>\n|, attr_quote: ?")

      assert_render(%q|%a{ data: '/' }|, %Q|<a data="/"></a>\n|, attr_quote: ?")
      assert_render(%q|%a{ data: { url: '/' } }|, %Q|<a data-url="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = '/'\n%a{ data: val }|, %Q|<a data="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = { url: '/' }\n%a{ data: val }|, %Q|<a data-url="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- hash = { data: { url: '/' } }\n%a{ hash }|, %Q|<a data-url="/"></a>\n|, attr_quote: ?")

      assert_render(%q|%a{ disabled: '/' }|, %Q|<a disabled="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = '/'\n%a{ disabled: val }|, %Q|<a disabled="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- hash = { disabled: '/' }\n%a{ hash }|, %Q|<a disabled="/"></a>\n|, attr_quote: ?")

      assert_render(%q|%a{ href: '/' }|, %Q|<a href="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- val = '/'\n%a{ href: val }|, %Q|<a href="/"></a>\n|, attr_quote: ?")
      assert_render(%Q|- hash = { href: '/' }\n%a{ hash }|, %Q|<a href="/"></a>\n|, attr_quote: ?")
    end
  end
end
