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

UserRegistry = Class
{
    Fields = {
        users = 'Set(User)'
    },
    Methods = {
        register = '(User)',
    }
}
