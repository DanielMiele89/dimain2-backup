CREATE TABLE [InsightArchive].[PizzaHut_To_Move] (
    [RetailOutletID]     INT           IDENTITY (1, 1) NOT NULL,
    [MerchantID]         NVARCHAR (50) NOT NULL,
    [PartnerID]          INT           NOT NULL,
    [Partner_To_Move_To] VARCHAR (4)   NOT NULL
);

