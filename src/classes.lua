local WebShoppe = _ENV

Shared = Module
{
    Money = Class{},
    Address = Class{},
    Name = Class{},
    Email = Class{},
    Token = Class{},
    ProductID = Class{},
    PaymentMethod = Enum {
        'WireTransfer',
        'CashOnDelivery',
    },
    ProductID = Class{},
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

    Customer:specialize{User}
    {
    }

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
        
        View = Abstract
        {
            Methods = {
                render = '()',
            },
        }
    end

    Customer = Module{}
    do
        local _ENV = Customer
        
        Cart = Class
        {
            Fields = {
                items = '(ItemID,Natural)',
            },
            Methods = {
                clear = '()',
                price = '():Money',
            }
        }

        Views = Module{}
        do
            local _ENV = Views
            
            local View = Shared.View
            
            Browsing:specialize{View}
            {
                Fields = {
                    filter = 'InventoryQuery //stored in view coz the user probly want this saved',
                    listing = '(ProductID,Logical) //product + is it in stock',
                    cart = 'Cart'
                },
                Methods = {
                    list = '(filtered:Logical)',
                    pay = '():CheckCart',
                    add = '(product:ProductID,quantity:Natural)',
                }
            }:associate{CheckCart,WebShoppe.Shared.ProductID}

            CheckCart:specialize{View}
            {
                Methods = {
                    remove = '(product:Product)',
                    setQuantity = '(product:Product,quantity:Natural)',
                    clear = '():Browsing',
                    totalPrice = '():Money',
                    pay = '():PaymentMethodSelection',
                }
            }:associate{Product,PaymentMethodSelection}

            PaymentMethodSelection:specialize{View}
            {
                Fields = {
                    method = 'PaymentMethod',
                },
                Methods = {
                    selectMethod = '(method:PaymentMethod)',
                    confirm = '():Browsing',
                }
            }:associate{Browsing,PaymentMethod}
        end
    end
    
    Vendor = Module{}
    do
        local _ENV = Vendor

        Order = Class
        {
            Fields = public
            {
                items = '(ProductID,Natural)'
            },
        }

        Views = Module {}
        do
            local _ENV = Views
            IncomingOrders:specialize{View}
            {
                Fields = {
                    orders = 'Vendor.Order',
                },
            }

            SingleOrder:specialize{View}
            {
                
            }

            AddProduct:specialize{View}
            {
                Methods = {
                }
            }
        end
    end
end
