WebShoppe = _ENV

do
    --[[PRELUDE]]
    --Copy = Interface{Comment = 'marker trait'}
    
    Natural{Comment = 'Természetes számok, beleértve a nullát'}
    Logical = Enum
    {
        'True',
        'False',
    }{Comment = 'Logikai értékek'}
    Template(Set, '<T>'){Comment = 'Hash halmaz'}
    {
        Fields = {
            add = '(<T>)->()',
            remove = '()->()',
        }
    }
    Template(Maybe, '<T>'){Comment = 'Egy opcionális T-típusú érték'}
    Text{Comment = 'Nyomtatható Unicode szöveg'}
    Any{Comment = 'Futásidejű dinamikus típus'}
    Template(Range, '<T>')
    {
        Comment = 'Egy - bármely oldalán nyitott - intervallum'
    }
    Byte{Comment = '8-bites érték'}
    Date{Comment = 'Naptári dátum'}
    UUID
    {
        Comment = 'Univerzálisan Egyedi Azonosító',
        Fields = {
            bytes = '[128]Byte',
        }
    }
end
do
    --[[SHARED]]
    Currency = Enum
    {
        'USD',
        'HUF',
        'EUR',
        'JPY',
        'AUD',
    }{Comment = 'Valuták azonosítói'}
    Money{Comment = 'Pénz'}
    {
        Fields = {
            amount = 'Natural',
            currency = 'Currency',
        }
    }
    Address{Comment = 'Full address of a person'}
    Name{Comment = 'A valid name for a person'}
    Email{Comment = 'A valid email address'}
    Token{Command = 'Token of a login session'}
    {
        Fields = {
            expires = 'Date',
            bytes = '[]Byte',
        }
    }
    Hash = Enum
    {
        'md5',
        'sha256'
    }{Comment = 'Identifier of a crpytographic hash function'}

    Password
    {
        Comment = 'A user\'s password, stored as a hash',
        Fields = {
            bytes = '[]Byte',
            salt = '[]Byte',
            hash = 'Hash',
        }
    }
    ProductID
    {
        Comment = 'Unique identifier for a product',
        Fields = {
            id = 'UUID',
        }
    }
    PaymentMethod = Enum {
        'WireTransfer',
        'CashOnDelivery',
    }{Comment = 'Method of payment'}
    InventoryQuery = Class
    {
        Comment = 'A filter for products',
        Fields = public {
            name = 'Maybe<Text>',
            producer = 'Maybe<Text>',
            priceRange = 'Maybe<Range<Money>>',
        },
    }
end

Server = Module{}
do
    local _ENV = Server

    DBConnection = Class
    {
        Comment = 'Connection to a backing database',
    }
    
    User = Abstract
    {
        Comment = 'Base class for vendors and customers',
        Fields = public{
            name = 'Name',
            address = 'Address',
            email = 'Email',
            password = 'Password',
            tokens = 'Set<Token>',
        },
    }

    Customer:specialize{User}{Comment = 'Buyer of goods'}
    Vendor:specialize{User}{Comment = 'Seller of goods'}

    Server = Class
    {
        Comment = 'Server instance',
        Fields = {
            storage = 'DBConnection //connection to backend',
            users = 'Set<User>',
            products = 'Set<Product>',
        },
        Methods = {
            register = User.Methods.User,
        }
    }

    Product = Abstract
    {
        Comment = 'Server side description of a product',
        Fields = public {
            id = 'ProductID',
            name = 'Text',
            producer = 'Text',
            price = 'Money',
            stock = 'Natural',
            misc = 'Any',
        },
    }

    Products = Module{}
    do
        local _ENV = Products
        Food = Class
        {
            Comment = 'Edible goods',
            Fields = {
                vegan = 'Logical',
            }
        }
        Clothing = Class
        {
            Comment = 'Stuff to cover your flesh prison with',
            Fields = {
                machineWashable = 'Logical',
            }
        }
        Beds = Class
        {
            Comment = 'For when you\'ve been slaving away at making a DSL to make UML bearable',
            Fields = {
                bunks = 'Maybe<Natural>',
                kingsized = 'Logical',
            }
        }
    end
end

Clients = Module{}
do
    local _ENV = Clients

    Token = Class
    {
        Comment = 'Browser cookie',
        Fields = {
            bytes = '[]Byte',
        }
    }
    
    Session = Abstract
    {
        Comment = 'Base class for a customer or vendor login session',
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
        Comment = 'Base class for views, which can at the least be rendered',
        Methods = {
            render = '()',
        },
    }

    Customer = Module{}
    do
        local _ENV = Customer
        
        Cart = Class
        {
            Comment = 'A vásárló kosara',
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
