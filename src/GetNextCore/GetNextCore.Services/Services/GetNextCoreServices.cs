using Remanufacturing.Messages;
using Remanufacturing.Responses;
using Remanufacturing.Services;
using System.Net;

namespace Remanufacturing.OrderNextCore.Services;

public class GetNextCoreServices(GetNextCoreServicesOptions options)
{

	private readonly GetNextCoreServicesOptions _servicesOptions = options;

	public async Task<IResponse> RequestNextCoreInformationAsync(OrderNextCoreMessage orderNextCoreMessage, string instance)
	{
		try
		{
			ArgumentException.ThrowIfNullOrEmpty(orderNextCoreMessage.PodId, nameof(orderNextCoreMessage.PodId));
			if (orderNextCoreMessage.RequestDateTime == default)
				orderNextCoreMessage.RequestDateTime = DateTime.UtcNow;
			await ServiceBusServices.SendMessageAsync(_servicesOptions.ServiceBusClient, _servicesOptions.GetNextCoreTopicName, orderNextCoreMessage);
			return new StandardResponse()
			{
				Type = "https://httpstatuses.com/201", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "Request for next core id sent.",
				Status = HttpStatusCode.Created,
				Detail = "The request for the next core id has been sent to the Production Schedule.",
				Instance = instance,
				Extensions = new Dictionary<string, object>()
				{
					{ "PodId", orderNextCoreMessage.PodId },
				}
			};
		}
		catch (ArgumentException ex)
		{
			return new ProblemDetails(ex, instance);
		}
		catch (Exception ex)
		{
			return new ProblemDetails()
			{
				Type = "https://httpstatuses.com/500", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "An error occurred while sending the message to the Service Bus",
				Status = HttpStatusCode.InternalServerError,
				Detail = ex.Message, // HACK: In a real-world scenario, you would not want to expose the exception message to the client.
				Instance = instance
			};
		}
	}

}