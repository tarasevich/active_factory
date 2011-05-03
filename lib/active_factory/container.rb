module ActiveFactory

  # keeps collection of created instances of the given model class
  class Container
    attr_accessor :entries
    attr_reader :name, :factory

    def initialize name, factory, context
      @name = name
      @factory = factory
      @context = context
      @entries = [].freeze
    end

    def create count
      dup_with add_entries count
    end

    def singleton
      if @entries.none?
        add_entries 1
      elsif @entries.many?
        raise "Multiple instances were declared for model :#{@name}."+
              "Use <#{@name.to_s.pluralize}> to access them"
      end
      self
    end

    def zip_merge *hashes
      @entries.size == hashes.size or raise

      @entries.zip(hashes) { |entry, hash|
        entry.merge hash
      }
      self
    end

    def build
      @entries.each &:build
      self
    end

    def make_linker
      Linker.new self
    end

    def before_save
      @entries.each &:before_save
    end

    def save
      @entries.each &:save
    end

    def attrs
      @entries.map &:attrs
    end

    def objects
      @entries.map &:model
    end

    private

    def dup_with entries
      that = clone
      that.entries = entries
      that
    end

    def add_entries count
      size = @entries.size
      added = (size...size+count).
          map { |i| ContainerEntry.new i, factory, @context }
      @entries = (@entries + added).freeze
      added
    end
  end
end