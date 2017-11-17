WebShoppe = _ENV

Prelude = Module{}
do
    local _ENV = Prelude
    Natural{Comment = 'Természetes számok, beleértve a nullát'}
    Logical = Enum
    {
        'True',
        'False',
    }{Comment = 'Logikai értékek'}
    Template(Set, '<T>')
    {
        Fields = {
            add = '(<T>)',
            remove = '()',
        }
    }
    Template(Maybe, '<T>'){Comment = 'Egy opcionális T-típusú érték'}
    Text{Comment = 'Nyomtatható Unicode szöveg'}
    Any{Comment = 'Futásidejű dinamikus típus'}
    Template(Range, '<T>')
    {
        Comment = 'Egy - bármely oldalán nyitott - intervallum'
    }
    Byte{}
    Time{}
    UUID
    {
        Comment = 'Univerzálisan Egyedi Azonosító',
        Fields = {
            bytes = '[128]Byte',
        }
    }
end

Shared = Module{}
do
    local _ENV = Shared
    Currency = Enum
    {
        'USD',
        'HUF',
        'EUR',
        'JPY',
        'AUD',
    }{Comment = 'Valuták azonosítói'}
    Money
    {
        Desc = 'Az árakat és egyéb összegeket a valuta nevével együtt tároljuk, főleg azért, hogy extra típusellenőrzést kapjunk.',
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
    }{
        Comment = 'Kriptografikus ellenőrzőösszegek azonosítói',
        Desc = 'Azért tároljuk hogy lehessen inkrementálisan frissíteni az auth rendszert',
     }

    Password
    {
        Comment = 'Egy felhasználó jelszava, ellenőrzőösszeggel és sóval együtt mentve',
        Desc = 'a sót mindig a jelszó elé illesztjük hashelés előtt',
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

    CustomerID
    {
        Fields = {
            id = 'Email',
        }
    }

    PaymentMethod = Enum {
        'WireTransfer',
        'CashOnDelivery',
    }{Comment = 'Fizetési metódusok'}

    InventoryQuery = Class
    {
        Comment = 'Szűrő termékekhez',
        Desc = 'Az összes mezője opcionális',
        Fields = public {
            name = 'Maybe<Text> //név (részlete)',
            producer = 'Maybe<Text> //gyártó név (részlete)',
            priceRange = 'Maybe<Range<Money>> //ár alsó és felő határértéke, lehetnek végtelenek',
        },
    }
    
    Order = Class
    {
        Comment = 'Rendelés',
        Desc = '',
        Fields = public
        {
            items = '(ProductID,Natural) //termékkód + darabszám',
            customer = 'CustomerID',
            state = 'OrderState',
            initdate = 'Date',
        },
    }
    
    OrderState = Enum
    {
        "Processing",
        "UnderWork",
        "EnRoute",
        "Closed",
    }{Comment = 'Rendelés állapota'}

    for _, cls in pairs(Prelude) do
        cls.hide = true
    end
    
    Products = Module{}
    do
        local _ENV = Products
        Details = Class
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
end

using {
    Prelude,
    Shared
}

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

    local function tranz(cls,opt)
        local lbl = getdef(opt,'labels',{})
        lbl.label = 'állapotátmenet'
        return cls:associate(opt)
    end

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
            login = '(email:Email,password:Password) //itt divergál az állapot az alapján hogy a token milyen felhasználóhoz tartozik',
        },
    }

    local function transition(a,b,opt)
    end
    
    View = Abstract
    {
        Comment = 'Nézet alaposztálya, ezen keresztül irányítja a felhasználó a munkamenetet',
        Methods = {
            render = '()',
            move = '()->View',
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
            
            tranz(Browsing:specialize{View}
            {
                Comment = 'Raktáron lévő árucikkek böngészése',
                Fields = {
                    filter = 'InventoryQuery',
                    listing = '(Products.Product,Logical) //termék + van-e raktáron',
                },
                Methods = {
                    pay = '()->CheckCart //fizetés indítása',
                    add = '(product:ProductID,quantity:Natural) //termék hozzáadása a kosárhoz',
                    myorders = '()->MyOrders //eddigi rendelések megtekintése / aktívak nyomonkövetése',
                }
            },{MyOrders})

            tranz(CheckCart:specialize{View}
            {
                Methods = {
                    remove = '(product:Products.ProductID)',
                    setQuantity = '(product:Products.Product,quantity:Natural)',
                    clear = '()->Browsing //kosár ürítése, vissza a böngészéshez',
                    totalPrice = '()->Money',
                    pay = '()->PaymentMethodSelection //fizetés indítása',
                }
            },{PaymentMethodSelection,Browsing})

            tranz(PaymentMethodSelection:specialize{View}
            {
                Fields = {
                    method = 'PaymentMethod',
                },
                Methods = {
                    selectMethod = '(method:PaymentMethod)',
                    confirm = '()->MyOrders //rendelés véglegesítése, tovább a rendelések nézetre',
                    cancel = '()->Browsing //rendelés megszakítva, vissza a böngészéshez',
                }
            },{MyOrders,Browsing})

            tranz(MyOrders:specialize{View}
            {
                Fields = {
                    orders = 'Set<Order>',
                },
                Methods = {
                    back = '()->Browsing',
                }
            },{Browsing})
        end
    end
    
    Vendor = Module{}
    do
        local _ENV = Vendor

        Views = Module {}
        do
            local _ENV = Views
            
            tranz(Overview:specialize{View}
            {
                Methods = {
                    listProducts = '()->ProductListing //termékek listázása nézetbe',
                    addProduct = '()->AddProduct  //termék hozzáadása nézetbe',
                    viewOrders = '()->IncomingOrders //rendelések listázása nézetbe',
                },
            },{ProductListing,AddProduct,IncomingOrders})
            
            tranz(IncomingOrders:specialize{View}
            {
                Fields = {
                    orders = 'Set<Vendor.Order>',
                },
                Methods = {
                    view = '(order:Vendor.Order)->SingleOrder //state transfer',
                }
            },{SingleOrder})

            tranz(SingleOrder:specialize{View}
            {
                Fields = {
                    order = 'Order',
                },
                Methods = {
                    advanceOrderSate = '() //a rendelést a következő fázisba lépteti',
                    finish = '()->Overview //state transfer',
                }
            },{Overview})

            tranz(ProductListing:specialize{View}
            {
                Fields = {
                    listing = 'Set<Products.Product>',
                },
                Methods = {
                    modify = '(product:ProductID)->ModifyProduct //state transfer',
                }
            },{ModifyProduct})

            tranz(AddProduct:specialize{View}
            {
                Fields = {
                    product = 'Products.Details',
                },
                Methods = {
                    add = '() //hozzáadja az új terméket (csak termékleírás, id-t ezután kap csak)',
                    finish = '()->Overview //state transfer',
                }
            },{Overview})

            tranz(ModifyProduct:specialize{View}
            {
                Fields = {
                    product = 'Products.Product',
                },
                Methods = {
                    commit = '()->Overview //state transfer',
                }
            },{Overview})
        end
    end
end
