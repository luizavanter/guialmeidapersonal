defmodule GaPersonal.SanitizerTest do
  use ExUnit.Case, async: true

  alias GaPersonal.Sanitizer

  describe "sanitize/1" do
    test "returns nil for nil input" do
      assert Sanitizer.sanitize(nil) == nil
    end

    test "strips HTML tags" do
      assert Sanitizer.sanitize("<script>alert('xss')</script>Hello") == "alert('xss')Hello"
    end

    test "strips multiple HTML tags" do
      assert Sanitizer.sanitize("<b>bold</b> and <i>italic</i>") == "bold and italic"
    end

    test "normalizes multiple spaces" do
      assert Sanitizer.sanitize("hello    world") == "hello world"
    end

    test "trims whitespace" do
      assert Sanitizer.sanitize("  hello  ") == "hello"
    end

    test "handles clean input" do
      assert Sanitizer.sanitize("clean text") == "clean text"
    end

    test "handles empty string" do
      assert Sanitizer.sanitize("") == ""
    end

    test "handles combined HTML and whitespace" do
      assert Sanitizer.sanitize("  <div>hello</div>   <span>world</span>  ") == "hello world"
    end
  end

  describe "sanitize_list/1" do
    test "sanitizes each item in list" do
      assert Sanitizer.sanitize_list(["<b>one</b>", " two ", "three"]) == ["one", "two", "three"]
    end

    test "handles empty list" do
      assert Sanitizer.sanitize_list([]) == []
    end

    test "handles non-string items" do
      assert Sanitizer.sanitize_list([123, nil, "test"]) == [123, nil, "test"]
    end
  end
end
