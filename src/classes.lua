Server = Class
{
    Fields = {
        users = 'UserRegistry',
    },
    Methods = {
    }
}

User = Abstract
{
    Fields = {
        name = 'Name',
        email = 'Email',
        password = 'Password',
        address = 'Address'
    },
    Methods = {
    }
}

UserRegistry = Class
{
    Fields = {
        users = 'Set<Users>',
    },
    Methods = {
        register = '('..table.concat(values(User.Fields),',')..')'
    }
}

Customer = Class
{
    Fields = combine
    (
        User.Fields,
        {
            address = 'Address'
        }
    ),
}
Customer : implements (User)

Session = Interface
{
    Fields = {
        user = 'User',
        expired = 'bool'
    },
    Methods = {
        logout = '()'
    },
}
