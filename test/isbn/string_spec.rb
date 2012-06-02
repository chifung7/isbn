require "minitest/spec"
require_relative "../../lib/isbn/string"

MiniTest::Unit.autorun

describe ISBN::String do
  it 'should create a isbn string' do
    ISBNS.each do |a|
      isbn10_orig, isbn13_orig, isbn10, isbn13 = a

      s10 = ISBN::String.new isbn10_orig
      s10.must_equal isbn10

      s13 = ISBN::String.new isbn13_orig
      s13.must_equal isbn13

      r13 = s10.to_isbn13
      r13.must_equal isbn13
      r13.must_be_instance_of ISBN::String

      r10 = s13.to_isbn10
      r10.must_equal isbn10
      r10.must_be_instance_of ISBN::String
    end
  end

  it 'should rejects to convert to isbn-10 for 979 isbns' do
    s = ISBN::String.new "9790879392788"
    proc { s.to_isbn10 }.must_raise ISBN::No10DigitISBNAvailable
  end
  
  it 'should rejects invalid isbns' do
    proc { ISBN::String.new("074324382") }.must_raise ISBN::InvalidISBNError
    proc { ISBN::String.new("") }.must_raise ISBN::InvalidISBNError
    proc { ISBN::String.new(nil) }.must_raise ISBN::InvalidISBNError
    # invalid non-digits characters
    proc { ISBN::String.new("978074324382A") }.must_raise ISBN::InvalidISBNError
  end

  it 'should return String object back for other string operations' do
    s = ISBN::String.new "9790879392788"
    s.to_s.must_be_instance_of ::String
    (s + "FOO").must_be_instance_of ::String
  end

end
