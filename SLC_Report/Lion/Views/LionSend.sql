CREATE VIEW Lion.LionSend
AS
SELECT ID, Name, [Description], CreatedDate, CreatedBy, SendDate, EmailCampaignKey, [Status], ChannelID, ProcessMessage
	, Uploaded, TotalMembers, OfferPerMember, TotalNumberOfChunks, NumberOfChunksUploaded
FROM SLC_Snapshot.Lion.LionSend