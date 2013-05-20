require 'nokogiri'

module UnitedStates
  module Documents
    class Bills

      # elements to be turned into divs (must be listed explicitly)
      BLOCKS = %w{
        bill form amendment-form engrossed-amendment-form resolution-form
        legis-body resolution-body engrossed-amendment-body amendment-body 
        title
        amendment amendment-block amendment-instruction
        section subsection paragraph subparagraph subchapter clause
        quoted-block
        toc toc-entry
      }

      # elements to be turned into spans (unlisted elements default to inline)
      INLINES = %w{
        after-quoted-block quote
        internal-xref external-xref
        text header enum
        short-title official-title
      }

      # Given a path to an XML file published by the House or Senate,
      # produce an HTML version of the document at the given output.
      def self.process(text, options = {})
        doc = Nokogiri::XML text

        body = doc.root
        body.traverse do |node|

          if node.name == "metadata"
            node.remove
            next
          end

          # for some nodes, we'll preserve some attributes
          preserved = {}

          # <external-xref legal-doc="usc" parsable-cite="usc/12/5301"
          # cite check
          if (node.name == "external-xref") and (node.attributes["legal-doc"] and (node.attributes["legal-doc"].value == "usc"))
            preserved["data-citation-type"] = "usc"
            preserved["data-citation-id"] = node.attributes["parsable-cite"].value
          end

          # turn into a div or span with a class of its old name
          name = node.name
          if BLOCKS.include?(name)
            node.name = "div"
          else # inline
            node.name = "span"
          end
          preserved["class"] = name


          # strip out all attributes
          node.attributes.each do |key, value|
            node.attributes[key].remove
          end

          # restore just the ones we were going to preserve
          preserved.each do |key, value|
            node.set_attribute key, value
          end
        end

        body.to_html
      end

    end
  end
end