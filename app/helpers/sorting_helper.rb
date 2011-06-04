module SortingHelper
  def sorting_links
    content_tag('div', link_to(content_tag('span', t('sort')), '#', :class => 'button sort_link'), :class => 'fr') + content_tag('div', link_to(content_tag('span', t('finish_sort')), update_positions_settings_blocks_path, :class => 'button finish_sort_link hidden'), :class => 'fr')
  end
end