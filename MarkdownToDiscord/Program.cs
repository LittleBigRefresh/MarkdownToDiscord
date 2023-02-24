using System.Text.RegularExpressions;
using Discord;
using Discord.Rest;
using MarkdownToDiscord.Elements;

List<string> lines = File.ReadAllLines("test.md").ToList();

Regex linkRegex = new(@"\[([^\]]+)\]\(([^)]+)\)");
Regex imageRegex = new(@"!\[([^\]]+)\]\(([^)]+)\)");

List<IMarkdownElement> markdown = new();

foreach (string lineImmutable in lines)
{
    string line = lineImmutable;
    IMarkdownElement? element = null;
    
    foreach (Match match in imageRegex.Matches(line))
    {
        string altText = match.Groups[1].Value;
        string linkText = match.Groups[2].Value;
        
        element = new ImageMarkdownElement(linkText, altText);
    }

    if (line.StartsWith("# ")) 
        element = new HeaderMarkdownElement(line.Substring(2));

    if(element != null)
    {
        markdown.Add(element);
        continue;
    }

    foreach (Match match in linkRegex.Matches(line))
    {
        string altText = match.Groups[1].Value;
        string linkText = match.Groups[2].Value;
        
        line = line.Replace(match.Groups[0].Value, $"{altText}: <{linkText}>");
    }

    element = new TextMarkdownElement(line);
    markdown.Add(element);
}

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
    foreach (IMarkdownElement element in markdown)
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