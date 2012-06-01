require "minitest/spec"
require_relative "../lib/isbn"

MiniTest::Unit.autorun

describe ISBN do
  ISBNS_DATA = [ ["0820472670","9780820472676"], ["0763740381","9780763740382"], ["0547168292","9780547168296"],
            ["0415990793","9780415990790"], ["1596670274","9781596670273"], ["0618800565","9780618800568"],
            ["0812971256","9780812971255"], ["0465032117","9780465032112"], ["0721606318","9780721606316"],
            ["0887273939","9780887273933"], ["012781910X","9780127819105"], ["0736061819","9780736061810"],
            ["0763748951","9780763748951"], ["0470196181","9780470196182"], ["0736064036","9780736064033"],
            ["0743488040","9780743488044"], ["0470130733","9780470130735"], ["0816516502","9780816516506"],
            ["074324382X","9780743243827"], ["0887401392","9780887401398"], ["0582404800","9780582404809"],
            ["2906571385","9782906571389"], ["074324382x","9780743243827"], ["074324382-X","978-074324382-7"] ]
  ISBNS = ISBNS_DATA.map { |data| data + data.map { |isbn| isbn.delete('-').upcase } }

  describe '#validate' do
    it "should validate valid isbns" do
      ISBNS.each do |a|
        isbn10_orig, isbn13_orig, isbn10, isbn13 = a
        ISBN.validate(isbn10_orig).must_equal [isbn10, nil, isbn10[0..8], isbn10[9]]
        ISBN.validate(isbn13_orig).must_equal [isbn13, isbn13[0..2], isbn13[3..11], isbn13[12]]
      end
    end

    it "should rejects invalid isbns" do
      proc { ISBN.validate("074324382") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.validate("") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.validate(nil) }.must_raise ISBN::InvalidISBNError
      # invalid non-digits characters
      proc { ISBN.validate("978074324382A") }.must_raise ISBN::InvalidISBNError
      # use \A instead of ^ in regular expressions
      proc { ISBN.validate("978\n978571389") }.must_raise ISBN::InvalidISBNError
      # incorrect checksum
      proc { ISBN.validate("0820472671") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.validate("9780820472677") }.must_raise ISBN::InvalidISBNError

      # invalid characters e.g. Amazon ASIN
      proc { ISBN.validate("B000VH3XBA") }.must_raise ISBN::InvalidISBNError
      # incorrect checksum
      proc { ISBN.validate("0820472671") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.validate("9780820472677") }.must_raise ISBN::InvalidISBNError

    end
  end
  
  describe '#ten!' do
    it "should respond with a ten digit isbn" do
      ISBNS.each do |isbn|
        ISBN.ten!(isbn[1]).must_equal isbn[2]
        ISBN.ten!(isbn[0]).must_equal isbn[2]
        ISBN.ten(isbn[1]).must_equal isbn[2]
        ISBN.ten(isbn[0]).must_equal isbn[2]
      end
    end

    it "should rejects invalid isbn inputs" do
      proc { ISBN.ten!("9790879392788") }.must_raise ISBN::No10DigitISBNAvailable
      proc { ISBN.ten!("074324382") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.ten!("") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.ten!(nil) }.must_raise ISBN::InvalidISBNError
      # invalid non-digits characters
      proc { ISBN.ten!("978074324382A") }.must_raise ISBN::InvalidISBNError
      # use \A instead of ^ in regular expressions
      proc { ISBN.ten!("978\n978571389") }.must_raise ISBN::InvalidISBNError
      # incorrect checksum
      proc { ISBN.ten!("0820472671") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.ten!("9780820472677") }.must_raise ISBN::InvalidISBNError
    end

    it "should return nils for invalid isbn inputs" do
      ISBN.ten("9790879392788").must_equal nil
    end
  end

  describe '#thirteen!' do
    it "should respond with a thirteen digit isbn" do
      ISBNS.each do |isbn|
        ISBN.thirteen!(isbn[0]).must_equal isbn[3]
        ISBN.thirteen!(isbn[1]).must_equal isbn[3]
        ISBN.thirteen(isbn[0]).must_equal isbn[3]
        ISBN.thirteen(isbn[1]).must_equal isbn[3]
      end
    end

    it "should rejects invalid isbns" do
      proc { ISBN.thirteen!("97908793927888") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.thirteen!(nil) }.must_raise ISBN::InvalidISBNError
      proc { ISBN.thirteen!("") }.must_raise ISBN::InvalidISBNError
      # invalid characters e.g. Amazon ASIN
      proc { ISBN.thirteen!("B000VH3XBA") }.must_raise ISBN::InvalidISBNError
      # incorrect checksum
      proc { ISBN.thirteen!("0820472671") }.must_raise ISBN::InvalidISBNError
      proc { ISBN.thirteen!("9780820472677") }.must_raise ISBN::InvalidISBNError
    end

    it "should return nil for invalid isbns" do
      ISBN.thirteen("97908793927888").must_equal nil
    end
  end
  
  it "should convert a NEW isbn into USED" do
    ISBN.as_used!("9780820472676").must_equal "2900820472675"
    ISBN.as_used!("2900820472675").must_equal "2900820472675"
    ISBN.as_used!("9790879392788").must_equal "2910879392787"
    ISBN.as_used!("2910879392787").must_equal "2910879392787"
    ISBN.as_used!("0820472670").must_equal "2900820472675"
    ISBN.as_used("0820472670").must_equal "2900820472675"
    proc { ISBN.as_used!("082047267") }.must_raise ISBN::InvalidISBNError
    ISBN.as_used("082047267").must_equal nil
  end
  
  it "should convert a USED isbn into NEW" do
    ISBN.as_new!("2900820472675").must_equal "9780820472676"
    ISBN.as_new!("2910879392787").must_equal "9790879392788"
    ISBN.as_new!("9780820472676").must_equal "9780820472676"
    ISBN.as_new!("9790879392788").must_equal "9790879392788"
    ISBN.as_new!("0820472670").must_equal "0820472670"
    ISBN.as_new("0820472670").must_equal "0820472670"
    proc { ISBN.as_new!("082047267") }.must_raise ISBN::InvalidISBNError
    ISBN.as_new("082047267").must_equal nil
  end
  
  it "should test the validity of an isbn" do
    ISBN.valid?("9780763740382").must_equal true
    ISBN.valid?("9790879392788").must_equal true
    ISBN.valid?("2900820472675").must_equal true
    ISBN.valid?("012781910X").must_equal true
    ISBN.valid?("9887401392").must_equal false
    ISBN.valid?("082047267").must_equal false
    ISBN.valid?(nil).must_equal false

    ISBN.valid?("978074324382A").must_equal false
    ISBN.valid?("978\n978571389").must_equal false
  end
  
  it "should get isbn from source string" do
    ISBN.from_string("ISBN:978-83-7659-303-6\nmore of content").must_equal "978-83-7659-303-6"
  end
end

