puts "=> Removing all sharing service!"
SharingService.delete_all

facebook = SharingService.new
facebook.title = "Facebook"
facebook.url = "http://www.facebook.com/sharer.php?u={url}&t={title}"
facebook.image = "facebook.png"
facebook.save

twitter = SharingService.new
twitter.title = "Twitter"
twitter.url = "http://www.twitter.com/home?status={title}: {url}"
twitter.image = "twitter.png"
twitter.save