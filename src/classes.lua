WebShoppe = _ENV

do
    --[[PRELUDE]]
    Copy = Interface{Comment = 'marker trait'}
    
    Natural:implement{Copy}
    Logical:implement{Copy}
    Set:implement{Copy}:template '<T>'
    Maybe:implement{Copy}:template '<T>'
    Text:implement{Copy}
    Any:implement{Copy}
    Range:implement{Copy}:template '<T>'
end
do
    --[[SHARED]]
    Money:implement{Copy}
    Address:implement{Copy}
    Name:implement{Copy}
    Email:implement{Copy}
    Token:implement{Copy}
    Password:implement{Copy}
    ProductID:implement{Copy}
    PaymentMethod = Enum {
        'WireTransfer',
        'CashOnDelivery',
    }:implement{Copy}
    ProductID:implement{Copy}
    Server = Module{}
    InventoryQuery = Class
    {
        Fields = public {
            name = 'Maybe<Text>',
            producer = 'Maybe<Text>',
            priceRange = 'Maybe<Range<Money>>',
        },
    }:implement{Copy}
end
do
    local _ENV = Server
    User = Abstract
    {
        Fields = public{
            name = 'Name',
            address = 'Address',
            email = 'Email',
            password = 'Password',
            tokens = 'Set<Token>',
        },
    }

    Customer:specialize{User}
    {
    }

    Server = Class
    {
        Fields = {
            users = 'Set<User>',
            products = 'Set<Product>',
        },
        Methods = {
            register = User.Methods.User,
        }
    }

    Product = Class
    {
        Fields = public {
            id = 'ProductID',
            name = 'Text',
            producer = 'Text',
            price = 'Money',
            stock = 'Natural',
            misc = 'Any',
        },
    }
end

Clients = Module{}
do
    local _ENV = Clients
    
    Session = Abstract
    {
        Fields = {
            token = 'Maybe<Token> //is user logged in?',
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

    Customer = Module{}
    do
        local _ENV = Customer
        
        Cart = Class
        {
            Fields = {
                items = '(ProductID,Natural)',
            },
            Methods = {
                clear = '()',
                price = '()->Money',
            }
        }

        Views = Module{}
        do
            local _ENV = Views
            
            local View = View
            
            Browsing:specialize{View}
            {
                Fields = {
                    filter = 'InventoryQuery //stored in view coz the user probly want this saved',
                    listing = '(ProductID,Logical) //product + is it in stock',
                    cart = 'Cart'
                },
                Methods = {
                    list = '(filtered:Logical)',
                    pay = '()->CheckCart //state transfer',
                    add = '(product:ProductID,quantity:Natural)',
                }
            }

            CheckCart:specialize{View}
            {
                Methods = {
                    remove = '(product:Product)',
                    setQuantity = '(product:Product,quantity:Natural)',
                    clear = '()->Browsing //state transfer',
                    totalPrice = '()->Money',
                    pay = '()->PaymentMethodSelection //state transfer',
                }
            }

            PaymentMethodSelection:specialize{View}
            {
                Fields = {
                    method = 'PaymentMethod',
                },
                Methods = {
                    selectMethod = '(method:PaymentMethod)',
                    confirm = '()->Browsing //state transfer',
                    cancel = '()->Browsing //state transfer',
                }
            }
        end
    end
    
    Vendor = Module{}
    do
        local _ENV = Vendor

        Order = Class
        {
            Fields = public
            {
                items = '(ProductID,Natural)',
            },
        }

        Product = Class
        {
            Fields = public {
                name = 'Text',
                producer = 'Text',
                price = 'Money',
                stock = 'Natural',
                misc = 'Any',
            },
        }

        Views = Module {}
        do
            local _ENV = Views

            Overview:specialize{View}
            {
                Methods = {
                    listProducts = '()->Products //state transfer',
                    addProduct = '()->AddProduct  //state transfer',
                    viewOrders = '()->IncomingOrders //state transfer',
                },
            }
            
            IncomingOrders:specialize{View}
            {
                Fields = {
                    orders = 'Set<&Vendor.Order>',
                },
                Methods = {
                    view = '(order:Vendor.Order)->SingleOrder //state transfer',
                }
            }

            SingleOrder:specialize{View}
            {
                Fields = {
                    order = '&Vendor.Order',
                },
                Methods = {
                    finish = '()->Overview //state transfer',
                }
            }

            Products:specialize{View}
            {
                Fields = {
                    listing = 'Set<Vendor.Product>',
                },
                Methods = {
                    modify = '(product:ProductID)->ModifyProduct //state transfer',
                }
            }

            AddProduct:specialize{View}
            {
                Fields = {
                    product = 'Vendor.Product',
                },
                Methods = {
                    add = '()->()',
                    finish = '()->Overview //state transfer',
                }
            }

            ModifyProduct:specialize{View}
            {
                Fields = {
                    product = '&Vendor.Product',
                },
                Methods = {
                    commit = '()->Overview //state transfer',
                }
            }
        end
    end
end
