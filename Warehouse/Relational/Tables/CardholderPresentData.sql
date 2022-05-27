CREATE TABLE [Relational].[CardholderPresentData] (
    [CardholderPresentData] INT          NOT NULL,
    [Description]           VARCHAR (57) NOT NULL,
    PRIMARY KEY CLUSTERED ([CardholderPresentData] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[CardholderPresentData] TO [visa_etl_user]
    AS [dbo];

