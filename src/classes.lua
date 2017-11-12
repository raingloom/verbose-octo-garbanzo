Server = Module
{
}
do
    local _ENV = Server
    Database = Class
    {
    }

    Server = Class
    {
        Fields = {
            users = 'Set<User>',
            sessions = 'Set<Session>',
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

    Customer = Class
    {
        Fields = combine
        (
            User.Fields,
            {
                address = 'Address',
                basket = 'Basket',
            }
        ),
    }
    Customer : implements (User)

    Basket = Class
    {
        Fields = {
        },
    }

    Vendor = Class
    {
        Fields = combine
        (
            User.Fields,
            {
            }
        ),
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
end
Client = Class
{
}
