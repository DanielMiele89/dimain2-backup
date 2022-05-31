CREATE TABLE [kevinc].[Orders] (
    [orderid]        INT           IDENTITY (1, 1) NOT NULL,
    [custid]         INT           NULL,
    [empid]          INT           NOT NULL,
    [orderdate]      DATETIME      NOT NULL,
    [requireddate]   DATETIME      NOT NULL,
    [shippeddate]    DATETIME      NULL,
    [shipperid]      INT           NOT NULL,
    [freight]        MONEY         CONSTRAINT [DFT_Orders_freight] DEFAULT ((0)) NOT NULL,
    [shipname]       NVARCHAR (40) NOT NULL,
    [shipaddress]    NVARCHAR (60) NOT NULL,
    [shipcity]       NVARCHAR (15) NOT NULL,
    [shipregion]     NVARCHAR (15) NULL,
    [shippostalcode] NVARCHAR (10) NULL,
    [shipcountry]    NVARCHAR (15) NOT NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([orderid] ASC),
    CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([custid]) REFERENCES [kevinc].[Customers] ([custid]),
    CONSTRAINT [FK_Orders_Employees] FOREIGN KEY ([empid]) REFERENCES [kevinc].[Employees] ([empid]),
    CONSTRAINT [FK_Orders_Shippers] FOREIGN KEY ([shipperid]) REFERENCES [kevinc].[Shippers] ([shipperid])
);


GO
CREATE NONCLUSTERED INDEX [idx_nc_custid]
    ON [kevinc].[Orders]([custid] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_empid]
    ON [kevinc].[Orders]([empid] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_shipperid]
    ON [kevinc].[Orders]([shipperid] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_orderdate]
    ON [kevinc].[Orders]([orderdate] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_shippeddate]
    ON [kevinc].[Orders]([shippeddate] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_shippostalcode]
    ON [kevinc].[Orders]([shippostalcode] ASC);

