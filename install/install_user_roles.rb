########################################################################
# Installation of default privileges
########################################################################

puts "=> Installing default roles and rights ... "

rights = [ [:records, :edit_record],
           [:records, :create_record],
           [:records, :edit_record_metadata],
           [:records, :edit_locked_record],
           [:records, :import_from_file],
           [:datastore, :edit_dataset_description],
           [:datastore, :create_dataset],
           [:datastore, :destroy_dataset],
           [:users, :manage_users],
           [:users, :block_users],
           [:users, :grant_rights],
           [:comments, :moderate_comments],
           [:comments, :delete_comments],
           [:information, :view_hidden_fields],
           [:information, :view_hidden_records],
           [:information, :view_hidden_datasets],
           [:information, :search_in_hidden_fields],
           [:information, :search_in_hidden_records],
           [:information, :search_in_hidden_datasets],
           [:system, :use_in_development]
         ]

rights.each do | right_info |
    identifier = right_info[1].to_s
    category = right_info[0].to_s
    right = AccessRight.find_by_identifier(identifier)
    if not right
        right = AccessRight.new
        right.identifier = identifier
    end
    right.category = category
    right.save(false)
end

########################################################################
# Create default roles
########################################################################

puts "=> Creating default roles ... "

roles = {
        :user_manager => [:manage_users, :block_users, :grant_rights],
        :datastore_manager => [:edit_dataset_description, 
                                :create_dataset,
                                :destroy_dataset],
        :data_editor => [:edit_record, 
                                :create_record,
                                :edit_record_metadata,
                                :edit_locked_record,
                                :import_from_file,
                                :edit_dataset_description,
                                :view_hidden_fields,
                                :view_hidden_records,
                                :view_hidden_datasets,
                                :search_in_hidden_fields,
                                :search_in_hidden_records,
                                :search_in_hidden_datasets
                                ],
        :power_user => [:view_hidden_fields,
                                :view_hidden_records,
                                :view_hidden_datasets,
                                :search_in_hidden_fields,
                                :search_in_hidden_records
                                ]
    }

roles.keys.each do | role_name |
    rights = roles[role_name]
    role_name = role_name.to_s
    role = AccessRole.find_by_identifier(role_name)
    if not role
        role = AccessRole.new
        role.identifier = role_name
    end
    
    puts "-> adding role #{role_name} with #{rights.count} rights"
    role_rights = []

    rights.each do | right_name |
        right_name = right_name.to_s
        right = AccessRight.find_by_identifier(right_name)
        role_rights << right
    end

    role.access_rights = role_rights
    role.save(false)
end

########################################################################
# Installation of default user
########################################################################

puts "=> Installing default user (admin/admin) ... "

if not User.find_by_login("admin")
    user = User.new
    user.login = "admin"
    user.name = "Administrator"
    user.password = "admin"
    user.is_super_user = true
    user.save(false)
else
    puts "-> admin account already exists. If you want to reset the account, delete admin user from table and re-run this script"
end

