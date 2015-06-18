# -*- encoding : utf-8 -*-
if QualityStatus.count > 0
  raise RuntimeError, "Can't create quality statuses. The table already contains data."
end

puts "=> Installing quality statuses"

QualityStatus.create!({:name => "ok", :image => "ok"})
QualityStatus.create!({:name => "duplicate", :image => "warning"})
QualityStatus.create!({:name => "incomplete", :image => "warning"})
QualityStatus.create!({:name => "doubtful", :image => "warning"})
QualityStatus.create!({:name => "unclear", :image => "warning"})
QualityStatus.create!({:name => "absent", :image => "warning"}) 
