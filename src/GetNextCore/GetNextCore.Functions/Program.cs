using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Remanufacturing.OrderNextCore.Services;

GetNextCoreServicesOptions getNextCoreServicesOptions = new()
{
	ServiceBusClient = new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusConnectionString")!),
	GetNextCoreTopicName = Environment.GetEnvironmentVariable("GetNextCoreTopicName")!,
};

IHost host = new HostBuilder()
	.ConfigureFunctionsWebApplication()
	.ConfigureServices(services =>
	{
		services.AddApplicationInsightsTelemetryWorkerService();
		services.ConfigureFunctionsApplicationInsights();
		services.AddHttpClient();
		services.AddSingleton(new GetNextCoreServices(getNextCoreServicesOptions));
	})
	.Build();

host.Run();