module SolidusImportProducts
  module Parser
    def parse(strategy, data_file, options)
      if strategy == :csv
        Parser::Csv.new(data_file, options)
      else
        raise SolidusImportProducts::Exception::InvalidParseStrategy
      end
    end

    module_function :parse
  end
end
