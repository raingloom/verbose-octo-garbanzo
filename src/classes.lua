Shared = Module
{
    Money = Class{},
    Address = Class{},
    Name = Class{},
    Email = Class{},
    Token = Class{},
}


Server = Module{}
do
    local _ENV = Server
    User = Abstract
    {
        Fields = public{
            name = 'Name',
            address = 'Address',
            email = 'Email',
        },
        Methods = {
            User = '(email:Email, password:Password, address:Address, name:Name)',
        }
    }

    Customer = Class
    {
        Fields = combine(User.Fields),
    }
    Customer:specializes(User)

    Server = Class
    {
        Fields = {
            users = 'Set<User>',
        },
        Methods = {
            register = User.Methods.User,
        }
    }
end

Client = Module{}
do
    local _ENV = Client

    Product = Class{}
    
    Cart = Class
    {
        Fields = {
            items = '(ItemID,Natural) //again, tuple. good languages have them. use a good language.',
        },
        Methods = {
            clear = '()',
            price = '():Money',
        }
    }

    Views = Module{}
    do
        local _ENV = Views
        View = Abstract{}
        
        Browsing = Class
        {
            Fields = {
                filter = 'InventoryQuery //global for the client coz they probly want this saved',
                listing = '(Product,Logical) //product + is it in stock',
            },
            Methods = {
                listInventory = '(filtered:Logical):Self',
                pay = '():Cart'
            }
        }

        Cart = Class
        {
            Methods = {
                
            }
        }

        io.stderr:write(require'inspect'(Views))
        for _,cls in pairs(Views) do
            if cls~=View then
                cls:specializes(View)
            end
        end
    end

    CustomerSession = Class
    {
        Fields = {
            token = 'Maybe<Token>> //is user logged in?',
            view = 'View',
            cart = 'Cart',
            payMethod = 'PayMethod',
            state = 'SessionState',
        },
        Methods = {
            register = Server.User.Methods.User,
            login = '(email:Email,password:Password)',
            addProduct = '(product:Product,quantity:Natural)',
            removeProduct = '(product)',
            clearCart = '()',
            cartPriceTotal = '():Money',
            setPayMethod = '(method:PayMethod)',
            sendOrder = '()',
        },
    }
end
