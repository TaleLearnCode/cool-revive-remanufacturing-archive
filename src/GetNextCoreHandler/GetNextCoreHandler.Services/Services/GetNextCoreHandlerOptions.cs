using Azure.Messaging.ServiceBus;

namespace Remanufacturing.OrderNextCore.Services;

public class GetNextCoreServicesOptions
{
	public ServiceBusClient ServiceBusClient { get; set; } = null!;
	public string OrderNextCoreTopicName { get; set; } = null!;
	public Dictionary<string, Uri> GetNextCoreUris { get; set; } = [];
}