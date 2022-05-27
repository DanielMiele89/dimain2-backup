CREATE TABLE [Relational].[nFI_Partner_Deals] (
    [ID]            INT             NOT NULL,
    [ClubID]        INT             NULL,
    [PartnerID]     INT             NULL,
    [ManagedBy]     VARCHAR (100)   NULL,
    [StartDate]     DATE            NULL,
    [EndDate]       DATE            NULL,
    [Override]      DECIMAL (32, 3) NULL,
    [Publisher]     DECIMAL (5, 2)  NULL,
    [Reward]        DECIMAL (5, 2)  NULL,
    [FixedOverride] BIT             NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT VIEW DEFINITION
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT VIEW CHANGE TRACKING
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT TAKE OWNERSHIP
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT CONTROL
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Relational].[nFI_Partner_Deals] TO [Zoe]
    AS [dbo];

