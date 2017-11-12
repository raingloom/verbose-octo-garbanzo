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
        register = '('..table.concat(values(User.Fields),',')..')',
    }
}

SessionManager = Class
{
    Fields = {
        sessions = 'Set<Session>',
    },
    Methods = {
        login = '(Email,Password)->Maybe(Session)',
    }
}
Server : aggregates (SessionManager, {head = '1', tail = '1'})

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

Vendor = Class
{
}
Vendor : implements (User)

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
