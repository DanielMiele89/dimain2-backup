CREATE TABLE [Derived].[__RedemptionItem_Archived] (
    [RedeemID]           INT            NOT NULL,
    [RedeemType]         VARCHAR (8)    NULL,
    [PrivateDescription] NVARCHAR (100) NOT NULL,
    [Status]             BIT            NULL,
    CONSTRAINT [pk_RedeemID] PRIMARY KEY CLUSTERED ([RedeemID] ASC)
);

