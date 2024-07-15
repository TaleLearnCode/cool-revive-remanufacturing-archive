using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Remanufacturing.OrderNextCore.Services;

GetNextCoreServicesOptions getNextCoreServicesOptions = new()
{
	ServiceBusClient = new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusConnectionString")!),
	OrderNextCoreTopicName = Environment.GetEnvironmentVariable("OrderNextCoreTopicName")!,
	GetNextCoreUris = new Dictionary<string, Uri>()
	{
		// HACK: In a real-world scenario, you would want to set the URIs different so as to not hard-code them.
		{ "Pod123", new Uri(Environment.GetEnvironmentVariable("GetNextCoreUri123")!) }
	}
};

IHost host = new HostBuilder()
	.ConfigureFunctionsWebApplication()
	.ConfigureServices(services =>
	{
		services.AddApplicationInsightsTelemetryWorkerService();
		services.ConfigureFunctionsApplicationInsights();
		services.AddSingleton(new GetNextCoreHandlerServices(getNextCoreServicesOptions));
	})
	.Build();

host.Run();