CREATE TABLE [dbo].[IronOfferClub] (
    [ID]          INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IronOfferID] INT NOT NULL,
    [ClubID]      INT NOT NULL,
    CONSTRAINT [PK_IronOfferClub] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferClub] TO [virgin_etl_user]
    AS [dbo];

