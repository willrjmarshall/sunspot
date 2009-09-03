module Sunspot
  module DSL #:nodoc:
    #
    # This class presents a DSL for constructing queries using the
    # Sunspot.search method. Methods of this class are available inside the
    # search block. Much of the DSL's functionality is implemented by this
    # class's superclasses, Sunspot::DSL::FieldQuery and Sunspot::DSL::Scope
    #
    # See Sunspot.search for usage examples
    #
    class Query < FieldQuery
      # Specify a phrase that should be searched as fulltext. Only +text+
      # fields are searched - see DSL::Fields.text
      #
      # Keyword search is executed using Solr's dismax handler, which strikes
      # a good balance between powerful and foolproof. In particular,
      # well-matched quotation marks can be used to group phrases, and the
      # + and - modifiers work as expected. All other special Solr boolean
      # syntax is escaped, and mismatched quotes are ignored entirely.
      #
      # ==== Parameters
      #
      # keywords<String>:: phrase to perform fulltext search on
      #
      # ==== Options
      #
      # :fields<Array>::
      #   List of fields that should be searched for keywords. Defaults to all
      #   fields configured for the types under search.
      #
      def keywords(keywords, options = {}, &block)
        fulltext_base_query = @query.set_keywords(keywords, options)
        if block && fulltext_base_query
          Util.instance_eval_or_call(
            Fulltext.new(fulltext_base_query),
            &block
          )
        end
      end

      # Paginate your search. This works the same way as WillPaginate's
      # paginate().
      #
      # Note that Solr searches are _always_ paginated. Not calling #paginate is
      # the equivalent of calling:
      #
      #   paginate(:page => 1, :per_page => Sunspot.config.pagination.default_per_page)
      #
      # ==== Options (options)
      #
      # :page<Integer>:: The requested page (required)
      #
      # :per_page<Integer>::
      #   How many results to return per page. The default is the value in
      #   +Sunspot.config.pagination.default_per_page+
      #
      def paginate(options = {})
        page = options.delete(:page) || raise(ArgumentError, "paginate requires a :page argument")
        per_page = options.delete(:per_page)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page)
      end

      #TODO document
      def near(coordinates, miles)
        @query.add_location_restriction(coordinates, miles)
      end

      #TODO document
      def text_fields(&block)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@query.add_text_fields_scope),
          &block
        )
      end
    end
  end
end
