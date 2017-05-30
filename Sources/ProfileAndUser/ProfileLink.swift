//
//  ProfileLink.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 17.01.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import JWT
import SMART


/**
You can use instances of this class to link user profiles to known participants on a remote server, by way of JWT.
*/
public class ProfileLink {
	
	/// The full JSON Web Token (JWT) used with this link.
	public let token: String
	
	/// The secret the token was signed with.
	public let secret: String
	
	/// The JWT issuer (`iss`), if any.
	public let issuer: String?
	
	/// The JWT audience (`aud`), if any.
	public let audience: String?
	
	public let claimset: ClaimSet
	
	/**
	Designated initializer.
	*/
	public init(token: String, using secret: String, issuer: String? = nil, audience: String? = nil) throws {
		self.token = token
		self.secret = secret
		self.issuer = issuer
		self.audience = audience
		guard let secretData = secret.data(using: String.Encoding.utf8) else {
			throw OAuth2Error.utf8EncodeError
		}
		//print("--->  \(token)")
		self.claimset = try JWT.decode(token, algorithm: .hs256(secretData), verify: true, audience: audience, issuer: issuer)
	}
	
	
	// MARK: - Request Generation
	
	/**
	Returns the URL against which the link can be established. Uses the token's `aud` parameter and appends `/establish` to arrive at the
	final endpoint.
	*/
	public func establishURL() throws -> URL {
		guard let aud = claimset.audience else {
			throw C3Error.jwtMissingAudience
		}
		guard let url = URL(string: aud) else {
			throw C3Error.jwtInvalidAudience(aud)
		}
		return url.appendingPathComponent("establish")
	}
	
	/**
	Create and decorate FHIR Patient resource as needed for the /establish endpoint.
	
	- returns: Correctly configured Patient resource
	*/
	public func patientResource(user: User, dataEndpoint: URL) throws -> Patient {
		guard let userId = user.userId else {
			throw C3Error.userHasNoUserId
		}
		let patient = Patient()
		let ident = Identifier()
		ident.value = userId.fhir_string
		ident.system = dataEndpoint.fhir_url
		patient.identifier = [ident]
		return patient
	}
	
	/**
	Configures a `URLRequest` that can be used to establish the link.
	*/
	public func request(linking user: User, dataEndpoint: URL) throws -> URLRequest {
		let linkEndpoint = try establishURL()
		let pat = try patientResource(user: user, dataEndpoint: dataEndpoint)
		
		var req = URLRequest(url: linkEndpoint)
		req.httpMethod = "POST"
		req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		req.addValue("application/json", forHTTPHeaderField: "Content-type")
		req.httpBody = try JSONSerialization.data(withJSONObject: try pat.asJSON(), options: [])
		return req
	}
}

