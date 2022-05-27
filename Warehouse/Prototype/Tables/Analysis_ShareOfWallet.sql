CREATE TABLE [Prototype].[Analysis_ShareOfWallet] (
    [FromBrandID]              SMALLINT     NOT NULL,
    [ToBrandID]                SMALLINT     NOT NULL,
    [FromBrandName]            VARCHAR (50) NOT NULL,
    [ToBrandName]              VARCHAR (50) NOT NULL,
    [CINIDCount]               INT          NULL,
    [FromBrandID_Sales]        MONEY        NULL,
    [FromBrandID_Refund_Sales] MONEY        NULL,
    [FromBrandID_Trans]        INT          NULL,
    [FromBrandID_Refund_Trans] INT          NULL,
    [ToBrandID_Sales]          MONEY        NULL,
    [ToBrandID_Refund_Sales]   MONEY        NULL,
    [ToBrandID_Trans]          INT          NULL,
    [ToBrandID_Refund_Trans]   INT          NULL
);

