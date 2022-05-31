CREATE TABLE [kevinc].[Products] (
    [productid]    INT           IDENTITY (1, 1) NOT NULL,
    [productname]  NVARCHAR (40) NOT NULL,
    [supplierid]   INT           NOT NULL,
    [categoryid]   INT           NOT NULL,
    [unitprice]    MONEY         CONSTRAINT [DFT_Products_unitprice] DEFAULT ((0)) NOT NULL,
    [discontinued] BIT           CONSTRAINT [DFT_Products_discontinued] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([productid] ASC),
    CONSTRAINT [CHK_Products_unitprice] CHECK ([unitprice]>=(0)),
    CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([categoryid]) REFERENCES [kevinc].[Categories] ([categoryid]),
    CONSTRAINT [FK_Products_Suppliers] FOREIGN KEY ([supplierid]) REFERENCES [kevinc].[Suppliers] ([supplierid])
);


GO
CREATE NONCLUSTERED INDEX [idx_nc_categoryid]
    ON [kevinc].[Products]([categoryid] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_productname]
    ON [kevinc].[Products]([productname] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_supplierid]
    ON [kevinc].[Products]([supplierid] ASC);

