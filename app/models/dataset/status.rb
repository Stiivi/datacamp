module Dataset
  class Status
    attr_reader :status

    def initialize(values)
      @status = Set.new(values)
    end

    def all
      status
    end

    def find(name)
      if status.include?(name.to_s)
        name.to_s
      else
        raise KeyError, "status: #{name} not found"
      end
    end
  end
end