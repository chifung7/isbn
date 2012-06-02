module ISBN
  extend self
  
  VERSION = "2.0.7"

  class InvalidISBNError < RuntimeError; end
  class No10DigitISBNAvailable < RuntimeError; end
  class InvalidSourceString < RuntimeError; end

  private
  def create_silence_method(name)
    bang_method_name = name.to_s + '!'
    define_method(name) do |isbn|
      begin
        ISBN.send(bang_method_name, isbn)
      rescue
        nil
      end
    end
  end

  public
  def validate(isbn_orig)
    raise InvalidISBNError.new isbn_orig unless isbn_orig.is_a? ::String
    isbn = isbn_orig.delete("-")

    case isbn.size
    when 10 then
      if isbn =~ /\A(\d{9})([\dxX])\z/
        body, cksum = $1, $2
        if is_valid_isbn10?(isbn)
          return [isbn.upcase, nil, body, cksum.upcase]
        end
      end
    when 13 then
      if isbn =~ /\A(978|979|290|291)(\d{9})(\d)\z/
        prefix, body, cksum = $1, $2, $3
        return [isbn, prefix, body, cksum] if is_valid_isbn13?(isbn)
      end
    end

    raise InvalidISBNError.new isbn_orig
  end

  def ten!(isbn_orig)
    isbn, prefix, body, cksum = validate(isbn_orig)
    return isbn if prefix.nil? # already an isbn10
    raise No10DigitISBNAvailable.new isbn_orig if prefix == '979' or prefix == '291'

    cksum10 = isbn10_checksum(body)
    body << (cksum10 == 10 ? 'X' : cksum10.to_s)
    return body
  end
  alias :as_ten! :ten!

  create_silence_method(:ten)
  alias :as_ten :ten

  def thirteen!(isbn_orig)
    isbn, prefix, body, cksum = validate(isbn_orig)
    return isbn if prefix

    isbn12 = '978' + body
    return isbn12 << isbn13_checksum(isbn12).to_s
  end
  alias :as_thirteen! :thirteen!

  create_silence_method(:thirteen)
  alias :as_thirteen :thirteen
  
  def as_used!(isbn_orig)
    isbn, prefix, body, cksum = validate(isbn_orig)
    return isbn if prefix == '290' or prefix == '291'

    isbn12 = case prefix
             when '978' then '290' + body
             when '979' then '291' + body
             when nil then '290' + body
             else raise ISBN::InvalidISBNError.new isbn_orig
             end
    return isbn12 << isbn13_checksum(isbn12).to_s
  end
  alias :used! :as_used!

  create_silence_method(:as_used)
  alias :used :as_used

  def as_new!(isbn_orig)
    isbn, prefix, body, cksum = validate(isbn_orig)
    return isbn if prefix.nil? or prefix == '978' or prefix == '979'
    isbn12 = case prefix
             when '290' then '978' + body
             when '291' then '979' + body
             else raise ISBN::InvalidISBNError.new isbn_orig
             end
    return isbn12 << isbn13_checksum(isbn12).to_s
  end
  alias :unused! :as_new!

  create_silence_method(:as_new)
  alias :unused :as_new

  def valid?(isbn)
    validate(isbn)
    true
  rescue
    false
  end
  
  def from_image(url)
    require "open-uri"
    require "tempfile"
    tmp = Tempfile.new("tmp")
    tmp.write(open(url, "rb:binary").read)
    tmp.close
    isbn = %x{djpeg -pnm #{tmp.path} | gocr -}
    isbn.strip.gsub(" ", "").gsub(/o/i, "0").gsub("_", "2").gsub(/2J$/, "45")
  end
  
  def from_string(source)
    match = /(97[89][- ]){0,1}[0-9]{1,5}[- ][0-9]{1,7}[- ][0-9]{1,6}[- ][0-9X]/.match(source)
    raise InvalidSourceString unless match
    match.to_a.first
  end

  private
  # http://en.wikipedia.org/wiki/International_Standard_Book_Number
  def is_valid_isbn13?(isbn13)
    sum = 0
    13.times { |i| sum += i.modulo(2)==0 ? isbn13[i].to_i : isbn13[i].to_i*3 }
    0 == sum.modulo(10)
  end
  
  def isbn13_checksum(isbn12)
    sum = 0
    12.times { |i| sum += i.modulo(2)==0 ? isbn12[i].to_i : isbn12[i].to_i*3 }
    rem = sum.modulo(10)
    return rem == 0 ? 0 : 10 - rem
  end

  def is_valid_isbn10?(isbn10)
    a, b = 0, 0
    9.times do |i| 
        a += isbn10[i].to_i # Assumed already converted from ASCII to 0..9
        b += a
    end
    if isbn10[9] == 'x' or isbn10[9] == 'X'
      a += 10.to_i
    else
      a += isbn10[9].to_i
    end
    b += a

    return b.modulo(11) == 0
  end

  def isbn10_checksum(isbn9)
    a, b = 0, 0
    9.times do |i| 
        a += isbn9[i].to_i # Assumed already converted from ASCII to 0..9
        b += a
    end
    rem = (b + a).modulo(11)
    return rem == 0 ? 0 : 11 - rem
  end


end
