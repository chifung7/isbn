module ISBN
  class String < String
    def initialize(isbn_str)
      isbn, = ISBN.validate(isbn_str)
      super isbn
    end

    def to_isbn13
      self.size == 13 ? self : self.class.new(ISBN.thirteen!(self))
    end

    def to_isbn10
      self.size == 10 ? self : self.class.new(ISBN.ten!(self))
    end
  end
end

