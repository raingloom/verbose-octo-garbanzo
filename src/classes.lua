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
    Time{Comment = 'Időpont'}
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
    Address{Comment = 'Teljes postai cím'}
    Name{Comment = 'Érvényes személynév'}
    Email{Comment = 'Érvényes elektronikus levelézési cím'}
    Token{Command = 'Böngésző süti, lejárati időponttal'}
    {
        Fields = {
            expires = 'Time',
            bytes = '[]Byte',
        }
    }
    Hash = Enum
    {
        'md5',
        'sha256'
    }{Comment = 'Kriptografikus ellenőrzőösszegek azonosítói'}

    Password
    {
        Comment = 'Egy felhasználó jelszava, ellenőrzőösszeggel és sóval együtt mentve',
        Fields = {
            bytes = '[]Byte',
            salt = '[]Byte',
            hash = 'Hash',
        },
        Methods = {
            Check = '(pass:[]Byte)->Logical //összehasonlítja a tárolt összeget egy adott jelszóéval'
        }
    }
    
    ProductID
    {
        Comment = 'Egy termék egyedi azonosítója',
        Fields = {
            id = 'UUID',
        }
    }

    PaymentMethod = Enum {
        'WireTransfer',
        'CashOnDelivery',
    }{Comment = 'Fizetési metódusok'}

    InventoryQuery = Class
    {
        Comment = 'Szűrő termékekhez',
        Fields = public {
            name = 'Maybe<Text>',
            producer = 'Maybe<Text>',
            priceRange = 'Maybe<Range<Money>>',
            category = 'Maybe<>',
        },
    }
end

Products = Module{}
do
    local _ENV = Products
    Details = Abstract
    {
        Comment = 'Egy termék részletes tulajdonságai (alaposztály termékkategoriák számára)',
        Fields = public {
            name = 'Text',
            producer = 'Text',
            price = 'Money',
            stock = 'Natural',
            misc = 'Any',
        },
    }
    Product = Class
    {
        Comment = 'Termék azonosítója és részletes leírása',
        Fields = {
            id = 'ProductID',
            details = 'Details',
        }
    }
    Categories = Module{}
    do
        local _ENV = Categories
        Food:specialize{Details}
        {
            Fields = {
                vegan = 'Logical',
            }
        }
        Clothing:specialize{Details}
        {
            Fields = {
                machineWashable = 'Logical',
            }
        }
        Beds:specialize{Details}
        {
            Fields = {
                bunks = 'Maybe<Natural>',
                kingsized = 'Logical',
            }
        }
    end
end

Server = Module{}
do
    local _ENV = Server

    DBConnection = Class
    {
        Comment = 'Backend szerverhez kapcsolat',
    }
    
    User = Abstract
    {
        Comment = 'Alaposztály felhasználóknak',
        Fields = public{
            name = 'Name',
            address = 'Address',
            email = 'Email',
            password = 'Password',
            tokens = 'Set<Token>',
        },
    }

    Customer:specialize{User}{Comment = 'Vásárló szerveroldali reprezentációja'}
    Vendor:specialize{User}{Comment = 'Eladó szerveroldali reprezentációja'}

    Server = Class
    {
        Comment = 'Egy szerver példány',
        Fields = {
            storage = 'DBConnection',
            users = 'Set<User>',
            products = 'Set<Products.Product>',
        },
        Methods = {
            register = User.Methods.User,
        }
    }
end

Clients = Module{}
do
    local _ENV = Clients

    Token = Class
    {
        Comment = 'Böngésző süti',
        Fields = {
            bytes = '[]Byte',
        }
    }
    
    Session = Abstract
    {
        Comment = 'Böngésző munkamenet alaposztálya',
        Fields = {
            token = 'Maybe<Token>',
            view = 'View',
        },
        Methods = {
            register = Server.User.Methods.User,
            login = '(email:Email,password:Password)->() //itt divergál az állapot az alapján hogy a token milyen felhasználóhoz tartozik',
        },
    }

    local function transition(a,b,opt)
    end
    
    View = Abstract
    {
        Comment = 'Nézet alaposztálya, ezen keresztül irányítja a felhasználó a munkamenetet',
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
                    remove = '(product:Products.Product)',
                    setQuantity = '(product:Products.Product,quantity:Natural)',
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
                    selectMethod = '(method:PaymentMethod)->()',
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
