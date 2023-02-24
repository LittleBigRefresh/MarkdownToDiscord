using Discord;
using Discord.Rest;
using MarkdownToDiscord;
using MarkdownToDiscord.Elements;

MarkdownParser parser = new(File.ReadAllLines("test.md").ToList());

string token = File.ReadAllText("token.txt");

DiscordRestClient client = new(new DiscordRestConfig
{
    LogLevel = LogSeverity.Debug,
});

#pragma warning disable CS1998
client.Log += async message => Console.WriteLine(message);
#pragma warning restore CS1998

await client.LoginAsync(TokenType.Bot, token);

IChannel? channel = await client.GetChannelAsync(1078539918642516018);
if (channel == null) throw new ArgumentNullException(nameof(channel));

if (channel is IMessageChannel messageChannel)
{
    await foreach (IReadOnlyCollection<IMessage> messages in messageChannel.GetMessagesAsync(50))
    foreach (IMessage message in messages)
        await message.DeleteAsync();

    using HttpClient httpClient = new();
    httpClient.DefaultRequestHeaders.Add("Accept", "image/*");
    
    string buffer = string.Empty;
    foreach (IMarkdownElement element in parser.Parse())
    {
        switch (element)
        {
            case HeaderMarkdownElement headerElement:
                if (!string.IsNullOrWhiteSpace(buffer)) await messageChannel.SendMessageAsync(buffer);
                buffer = $"**{headerElement.Text}**\n\n";
                break;
            case TextMarkdownElement textElement:
                buffer += textElement.Text + '\n';
                break;
            case ImageMarkdownElement imageElement:
                Stream stream = await httpClient.GetStreamAsync(imageElement.Link);
                FileAttachment attachment = new(stream, "image.png", imageElement.AltText);
                
                // it's okay to not check for length here, we're free to send attachments with no message body
                await messageChannel.SendFileAsync(attachment, buffer);
                buffer = string.Empty;
                break;
        }
    }

    if (!string.IsNullOrWhiteSpace(buffer))
    {
        await messageChannel.SendMessageAsync(buffer.TrimEnd());
    }
}

await client.LogoutAsync();