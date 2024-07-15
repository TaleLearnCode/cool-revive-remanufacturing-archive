using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.Messages;
using Remanufacturing.OrderNextCore.Services;
using Remanufacturing.Responses;
using System.Text.Json;

namespace Remanufacturing.OrderNextCore.Functions;

public class GetNextCoreHandler(
	ILogger<GetNextCoreHandler> logger,
	IHttpClientFactory httpClientFactory,
	GetNextCoreHandlerServices getNextCoreHandlerServices)
{
	private readonly ILogger<GetNextCoreHandler> _logger = logger;
	private readonly HttpClient _httpClient = httpClientFactory.CreateClient();
	private readonly GetNextCoreHandlerServices _getNextCoreHandlerServices = getNextCoreHandlerServices;

	[Function("GetNextCoreForPod123Handler")]
	public async Task Run(
		[ServiceBusTrigger("%GetNextCoreTopicName%", "%GetNextCoreForPod123SubscriptionName%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message,
		ServiceBusMessageActions messageActions)
	{

		_logger.LogInformation("Message ID: {id}", message.MessageId);

		OrderNextCoreMessage? orderNextCoreMessage = JsonSerializer.Deserialize<OrderNextCoreMessage>(message.Body);
		if (orderNextCoreMessage == null)
		{
			_logger.LogError("Failed to deserialize the message body.");
			await messageActions.DeadLetterMessageAsync(message);
			return;
		}

		_logger.LogInformation("Get next core for pod {podId}", orderNextCoreMessage.PodId);

		IResponse getNextCoreInfoResponse = await _getNextCoreHandlerServices.GetNextCoreAsync(_httpClient, orderNextCoreMessage);
		if (getNextCoreInfoResponse is StandardResponse response)
		{
			orderNextCoreMessage.CoreId = response.Extensions!["CoreId"].ToString();
			orderNextCoreMessage.FinishedProductId = response.Extensions!["FinishedProductId"].ToString();
		}
		else
		{
			await messageActions.DeadLetterMessageAsync(message);
			return;
		}

		IResponse orderNextCoreResponse = await _getNextCoreHandlerServices.OrderNextCoreAsync(orderNextCoreMessage, message.MessageId);
		if (orderNextCoreResponse is ProblemDetails)
		{
			await messageActions.DeadLetterMessageAsync(message);
			return;
		}

		// Complete the message
		await messageActions.CompleteMessageAsync(message);

	}
}