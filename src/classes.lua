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

Clients = Module{}
do
    local _ENV = Clients
    
    Shared = Module {}
    do
        local _ENV = Shared
        Session = Abstract
        {
            Fields = {
                token = 'Maybe<Token>> //is user logged in?',
                view = 'View',
            },
            Methods = {
                register = Server.User.Methods.User,
                login = '(email:Email,password:Password)',
            },
        }
        
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

        View = Abstract
        {
            Methods = {
                render = '()',
            },
        }
    end
    
    local function spechelper(m)
        local View = Shared.View
        for _,cls in pairs(m) do
            if cls~=View then
                cls.Methods = combine(View.Methods, cls.Methods)
                cls.Fields = combine(View.Fields, cls.Fields)
                cls:specializes(View)
            end
        end
    end

    Customer = Module{}
    do
        local _ENV = Customer

        Views = Module{}
        do
            local _ENV = Views
            Browsing = Class
            {
                Fields = {
                    filter = 'InventoryQuery //stored in view coz the user probly want this saved',
                    listing = '(Product,Logical) //product + is it in stock',
                    cart = 'WebShoppe::Clients::Cart'
                },
                Methods = {
                    list = '(filtered:Logical)',
                    pay = '():Cart',
                    add = '(product:Product,quantity:Natural)',
                }
            }

            Cart = Class
            {
                Methods = {
                    remove = '(product:Product)',
                    setQuantity = '(product:Product,quantity:Natural)',
                    clear = '():Browsing',
                    totalPrice = '():Money',
                    pay = '():PaymentMethodSelection',
                }
            }

            PaymentMethodSelection = Class
            {
                Fields = {
                    method = 'PaymentMethod',
                },
                Methods = {
                    selectMethod = '(method:PaymentMethod)',
                    confirm = '():Browsing',
                }
            }
            spechelper(_ENV, Shared.View)
        end
    end
    
    Vendor = Module{}
    do
        local _ENV = Vendor
        local Views = Module {}
        do
            local _ENV = Views
            
            IncomingOrders = Class
            {
                
            }

            AddProduct = Class
            {
                Methods = {
                }
            }
            
            spechelper(_ENV)
        end
    end
end
