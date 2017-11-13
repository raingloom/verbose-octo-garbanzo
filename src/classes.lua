Shared = Module
{
    Money = Class{},
    Address = Class{},
    Name = Class{},
    Email = Class{},
}
do
    Server = Module{}
    local _ENV = Server
    User = Abstract
    {
        Fields = {
            name = 'Name',
            address = 'Address',
            email = 'Email',
        },
    }
end
