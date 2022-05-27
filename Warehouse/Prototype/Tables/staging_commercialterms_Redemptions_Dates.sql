CREATE TABLE [Prototype].[staging_commercialterms_Redemptions_Dates] (
    [RedeemID]           INT            NOT NULL,
    [RedeemType]         VARCHAR (8)    NULL,
    [PrivateDescription] NVARCHAR (100) NOT NULL,
    [Status]             BIT            NULL,
    [ItemID]             INT            NULL,
    [MinRedeemDate]      DATETIME       NULL,
    [MaxRedeemDate]      DATETIME       NULL
);

