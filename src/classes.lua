Server = Class
{
    Fields = {
        users = 'UserRegistry',
    },
}

User = Abstract
{
    Fields = {
        name = 'Name',
        email = 'Email',
        password = 'Password',
    },
    Methods = {
    }
}
getters(User)
setters(User)

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
getters(Customer)

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
