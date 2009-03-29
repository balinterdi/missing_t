* for message strings with dynamic parts, check if there is any translation that matches the non-dynamic part. Only output the message if none found. E.g

    user.friendships.make.#{action}
    
    will output user.friendships.make.#{action} if there are no translation strings that match user.friendships.make. (no matter what comes after the make.)