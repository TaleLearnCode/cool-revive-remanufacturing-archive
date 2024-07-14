using Azure.Messaging.ServiceBus;

namespace Remanufacturing.OrderNextCore.Services;

public class GetNextCoreServicesOptions
{
	public ServiceBusClient ServiceBusClient { get; set; } = null!;
	public string GetNextCoreTopicName { get; set; } = null!;
}