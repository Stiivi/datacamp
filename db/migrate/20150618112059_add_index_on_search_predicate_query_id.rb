class AddIndexOnSearchPredicateQueryId < ActiveRecord::Migration
  def change
    add_index :search_predicates, :search_query_id
  end
end
